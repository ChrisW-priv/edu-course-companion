terraform {
  backend "gcs" {
    bucket = "kw-edu-course-companion-ci-bucket"
    prefix = "terraform/state"
  }
}
