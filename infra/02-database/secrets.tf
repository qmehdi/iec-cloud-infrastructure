# -----------------------------------------------------------------------------
# An empty place to put the Yelp API key.
#
# We create the secret now but leave it empty. Later, scripts/set-yelp-key.sh
# puts a key into it and restarts the app. That's the lesson: the key is
# configuration, not code. Changing it doesn't rebuild a single thing.
#
# The app treats an empty secret as "no key": it hides the search bar and
# everything else keeps working.
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "yelp" {
  name        = "course/yelp-api-key"
  description = "Yelp Fusion API key for Neighborhood Eats. Empty until you set one."

  # Normally AWS keeps a deleted secret for 30 days in case you change your
  # mind, and refuses to let you reuse the name in the meantime. Zero means
  # "delete it immediately", so rebuilding the course next week just works.
  recovery_window_in_days = 0

  tags = {
    Name = "course-yelp-api-key"
  }
}
