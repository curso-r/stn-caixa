library(stats)
library(keras)
library(tensorflow)
library(tfdatasets)
library(stringr)
library(rray)
library(doMC)
library(magrittr)
library(tidyverse)
library(tidymodels)
library(furrr)
library(parsnip)
library(tune)
library(workflows) 
library(ranger)
library(numbers)
library(tictoc)

set.seed(1)

tic("rf tune")
# rotulos -------------
rotulos <- read_rds("data/rotulos.rds")

ts_das_disponibilidades_liquidas_com_indicadores <- readRDS("data/ts_das_disponibilidades_liquidas_com_indicadores.rds")

# gruda rotulos -------------------------------
ts_das_disponibilidades_liquidas_com_indicadores <- ts_das_disponibilidades_liquidas_com_indicadores %>%
  inner_join(
    rotulos,
    by = "id"
  ) %>%
  select(-serie_temporal, -serie_temporal_random_crop)

# Treino/Teste
ids_train <- initial_split(ts_das_disponibilidades_liquidas_com_indicadores)

modelo_train <- ids_train %>% training()
modelo_val <- ids_train %>% testing()

# Receita
modelo_recipe <- modelo_train %>%
  recipe(rotulo ~ .) %>%
  add_role(id, NO_UG, NO_ORGAO, NO_FONTE_RECURSO, n, new_role = "non_predictor") %>%
  remove_role(id, NO_UG, NO_ORGAO, NO_FONTE_RECURSO, n, old_role = "predictor") %>%
  prep()
write_rds(modelo_recipe, "data/modelo_recipe.rds")

# Modelo
modelo_model <- boost_tree(
  trees = tune(), 
  mtry = tune(), 
  min_n = tune(),
  tree_depth = tune(),
  learn_rate = tune(),
  loss_reduction = tune(),
  sample_size = tune()
) %>%
  set_engine("xgboost", verbose = 1) %>%
  set_mode("classification")

# Workflow
modelo_wflow <- workflow() %>%
  add_model(modelo_model) %>%
  add_recipe(modelo_recipe)

# Parâmetros
# modelo_params <- parameters(modelo_wflow, mtry = finalize(mtry(), modelo_train %>% select(-y)))
set.seed(1)
modelo_params <- expand_grid(
  mtry = c(2, 4, 6, 10),
  trees = c(1500),
  min_n = c(3, 5, 10),
  tree_depth = c(1, 2, 3, 5, 8),
  learn_rate = c(0.1),
  loss_reduction = c(1),
  sample_size = c(0.8)
) 

# Amostras CV
modelo_train_cv <- vfold_cv(modelo_train, v = 5)

# Grid Search
set.seed(1)
# doMC::registerDoMC(6)

modelo_search_res <- tune_grid(
  modelo_wflow, 
  resamples = modelo_train_cv,
  grid = modelo_params,
  metrics = metric_set(roc_auc, accuracy, recall, precision, kap),
  control = control_grid(verbose = TRUE, allow_par = FALSE)
)

# Best Model
modelo_search_res_table <- modelo_search_res %>%
  select(.metrics) %>%
  unnest_legacy() %>%
  select(-.estimator) %>%
  group_by_at(vars(-.estimate)) %>%
  summarise(
    estimate = mean(.estimate),
    se = sd(.estimate)/sqrt(n())
  )

modelo_search_res_table %>%
  ggplot(aes(x = mtry, y = estimate, colour = .metric)) +
  geom_errorbar(aes(ymin = estimate - 2*se, ymax = estimate + 2*se)) +
  facet_grid(.metric ~ learn_rate + trees + tree_depth)

modelo_best_params <- tune::select_best(modelo_search_res, "kap")
write_rds(modelo_search_res, "data/modelo_search_res.rds")
write_rds(modelo_best_params, "data/modelo_best_params.rds")

toc()




# Final Model --------------------------------------------------------------------------------
tic("modelo final fit")
# data
modelo_best_params <- read_rds("data/modelo_best_params.rds")
modelo_model_final <- do.call(boost_tree, as.list(modelo_best_params)) %>%
  set_engine("xgboost", verbose = 1) %>%
  set_mode("classification")

modelo_recipe <- read_rds("data/modelo_recipe.rds")
modelo_wflow_final <- workflow() %>%
  add_model(modelo_model_final) %>%
  add_recipe(modelo_recipe)

# fit
modelo <- fit(modelo_wflow_final, data =  modelo_train)

# performace
modelo_obs_vs_pred_train <- modelo_train %>%
  mutate(
    base = "train",
    suspeita_de_empocamento = predict(modelo, ., type = "prob")$.pred_Empoçamento,
    class = predict(modelo, ., type = "class")$.pred_class,
  )

modelo_obs_vs_pred_val <- modelo_val %>%
  mutate(
    base = "val",
    suspeita_de_empocamento = predict(modelo, ., type = "prob")$.pred_Empoçamento,
    class = predict(modelo, ., type = "class")$.pred_class,
  )

modelo_obs_vs_pred <- bind_rows(
  modelo_obs_vs_pred_train,
  modelo_obs_vs_pred_val
)

# confusion matrices
modelo_obs_vs_pred %>%
  count(base, class, rotulo) %>%
  spread(rotulo, n, fill = 0)

# metrics
modelo_obs_vs_pred %>%
  select(rotulo, suspeita_de_empocamento, class, base) %>%
  mutate(rotulo = as.factor(rotulo)) %>%
  group_by(base) %>%
  nest_legacy() %>%
  mutate(
    roc_auc = map_dbl(data, ~roc_auc(.x, rotulo, suspeita_de_empocamento)$.estimate),
    accuracy = map_dbl(data, ~accuracy(.x, rotulo, class)$.estimate),
    kappa = map_dbl(data, ~kap(.x, rotulo, class)$.estimate),
    recall = map_dbl(data, ~recall(.x, rotulo, class)$.estimate),
    precision = map_dbl(data, ~precision(.x, rotulo, class)$.estimate)
  )


# save
write_rds(modelo, "data/modelo.rds")
write_rds(modelo_wflow_final, "data/modelo_wflow_final.rds")
write_rds(modelo_obs_vs_pred, "data/modelo_obs_vs_pred.rds")

# pin
system("gcloud auth login")
pins::board_register_gcloud(bucket = "ministerio_da_justica")
pins::pin(modelo, "modelo_xgboost", "Modelo XGboost para 'empocamento' ajustado com dados do Ministerio da Justica", board = "gcloud")

toc()



#####
library(pdp)
library(xgboost)
mod <- modelo$fit$fit$fit

xgboost::xgb.importance(model = mod)


pred <- function(object, newdata) {predict(object, newdata, type = "prob")}
partial(
  mod,
  train = modelo_obs_vs_pred %>% 
    select(integral_sobre_media_dos_gastos, disponibilidade_estritamente_crescente, iadl, valor_nominal, valor_nominal_conservador, indicador_tempo), 
  pred.var = "indicador_tempo",
  pred.fun = pred,
  grid.resolution = 20,
  plot = TRUE,
  center = TRUE,
  plot.engine = "ggplot2"
)

predictor <- Predictor$new(mod, data = modelo_obs_vs_pred %>% 
                             select(valor_nominal, valor_nominal_conservador, 
                                    indicador_tempo, disponibilidade_estritamente_crescente, iadl, 
                                    integral_sobre_media_dos_gastos) %>% xgb.DMatrix(), y = modelo_obs_vs_pred$rotulo)
str(predictor)

pdp_obj <- Partial$new(predictor, feature = "valor_nominal")
pdp_obj$center(min(wine_train$alcohol))
glimpse(pdp_obj$results)
pdp_obj$plot()
