resource "google_bigquery_dataset" "default" {
  dataset_id  = "movie_analytics"
  description = "Central repository for movie reviews, user purchases, and activity logs. Used for insights into user sentiments, behaviors, and platform interactions."
  location    = "US"
}

resource "google_bigquery_table" "log_stg" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "log_stg"
}

resource "google_bigquery_table" "user_purchase_stg" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "user_purchase_stg"
}

resource "google_bigquery_table" "movie_review_stg" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "movie_review_stg"
}