terraform {
  backend "gcs" {
    bucket = "kw-edu-course-companion-2-ci-bucket"
    prefix = "terraform/state"
  }
}
