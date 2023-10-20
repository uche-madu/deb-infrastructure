resource "google_bigquery_dataset" "default" {
  dataset_id  = "movie_analytics"
  description = "Central repository for movie reviews, user purchases, and activity logs. Used for insights into user sentiments, behaviors, and platform interactions."
  location    = "US"
}

resource "google_bigquery_table" "user_purchase" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = "user_purchase"
  deletion_protection = false
}

resource "google_bigquery_table" "review_logs" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = "review_logs"
  deletion_protection = false
  
  time_partitioning {
    type = "DAY"   
    field = "day"
  }
}

resource "google_bigquery_table" "classified_movie_review" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = "classified_movie_review"
  deletion_protection = false

  time_partitioning {
    type = "DAY"
    field = "insert_date"
  }
}
