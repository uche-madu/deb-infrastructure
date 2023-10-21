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

  schema = <<EOF
  [
    {
      "name": "log_id",
      "type": "INTEGER",
      "mode": "REQUIRED"
    },
    {
      "name": "log_date",
      "type": "DATE",
      "mode": "REQUIRED"
    },
    {
      "name": "device",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "os",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "location",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "ip",
      "type": "STRING",
      "mode": "NULLABLE"
    },
    {
      "name": "phone_number",
      "type": "STRING",
      "mode": "NULLABLE"
    }
  ]
  EOF

  time_partitioning {
    type = "DAY"
  }
}


resource "google_bigquery_table" "classified_movie_review" {
  dataset_id          = google_bigquery_dataset.default.dataset_id
  table_id            = "classified_movie_review"
  deletion_protection = false

  schema = <<EOF
  [
    {
      "name": "user_id",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "positive_review",
      "type": "INTEGER",
      "mode": "REQUIRED"
    },
    {
      "name": "review_id",
      "type": "INTEGER",
      "mode": "REQUIRED"
    },
    {
      "name": "insert_date",
      "type": "TIMESTAMP",
      "mode": "REQUIRED"
    }
  ]
  EOF

  time_partitioning {
    type  = "DAY"
    field = "insert_date"
  }
}

