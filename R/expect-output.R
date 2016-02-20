#' Expectation: does code produce output/message/warning/error?
#'
#' Use \code{expect_output()}, \code{expect_message()}, \code{expect_warning()},
#' or \code{expect_error()} to check for specific outputs. Use
#' \code{expect_silent()} to assert that there should be no output of
#' any type.
#'
#' @inheritParams expect_that
#' @inheritParams expect_match
#' @param regexp regular expression to test against.
#'
#'   If \code{NULL}, the default, asserts that there should be an output,
#'   a messsage, a warning, or an error, but does not test for specific value.
#'
#'   If \code{NA}, asserts that there should be no output, messages, warnings,
#'   or errors.
#' @param all For messages and warnings, do all need to the \code{regexp}
#'    (TRUE), or does only one need to match (FALSE)
#' @family expectations
#' @examples
#' # Output --------------------------------------------------------------------
#' str(mtcars)
#' expect_output(str(mtcars), "32 obs")
#' expect_output(str(mtcars), "11 variables")
#'
#' # You can use the arguments of grepl to control the matching
#' expect_output(str(mtcars), "11 VARIABLES", ignore.case = TRUE)
#' expect_output(str(mtcars), "$ mpg", fixed = TRUE)
#'
#' # Messages ------------------------------------------------------------------
#'
#' f <- function(x) {
#'   if (x < 0) message("*x* is already negative")
#'   -x
#' }
#' expect_message(f(-1))
#' expect_message(f(-1), "already negative")
#' expect_message(f(1), NA)
#'
#' # You can use the arguments of grepl to control the matching
#' expect_message(f(-1), "*x*", fixed = TRUE)
#' expect_message(f(-1), "NEGATIVE", ignore.case = TRUE)
#'
#' # Warnings --------------------------------------------------------------------
#' f <- function(x) {
#'   if (x < 0) warning("*x* is already negative")
#'   -x
#' }
#' expect_warning(f(-1))
#' expect_warning(f(-1), "already negative")
#' expect_warning(f(1), NA)
#'
#' # You can use the arguments of grepl to control the matching
#' expect_warning(f(-1), "*x*", fixed = TRUE)
#' expect_warning(f(-1), "NEGATIVE", ignore.case = TRUE)
#'
#' # Errors --------------------------------------------------------------------
#' f <- function() stop("My error!")
#' expect_error(f())
#' expect_error(f(), "My error!")
#'
#' # You can use the arguments of grepl to control the matching
#' expect_error(f(), "my error!", ignore.case = TRUE)
#'
#' # Silent --------------------------------------------------------------------
#' expect_silent("123")
#'
#' f <- function() {
#'   message("Hi!")
#'   warning("Hey!!")
#'   print("OY!!!")
#' }
#' \dontrun{
#' expect_silent(f())
#' }

#' @name output-expectations
NULL

#' @export
#' @rdname output-expectations
expect_output <- function(object, regexp = NULL, ..., info = NULL, label = NULL) {
  lab <- make_label(object, info = info, label = label)
  output <- evaluate_promise(object)$output

  if (identical(regexp, NA)) {
    expect(
      identical(output, ""),
      sprintf("%s produced output.\n%s", lab, encodeString(output))
    )
  } else if (is.null(regexp)) {
    expect(
      !identical(output, ""),
      sprintf("%s produced no output", lab)
    )
  } else {
    expect_match(output, regexp, ...)
  }
}


#' @export
#' @rdname output-expectations
expect_error <- function(object, regexp = NULL, ..., info = NULL,
  label = NULL) {

  lab <- make_label(object, info = info, label = label)

  error <- tryCatch(
    {
      object
      NULL
    },
    error = function(e) {
      e
    }
  )

  if (identical(regexp, NA)) {
    expect(
      is.null(error),
      sprintf("%s threw an error.\n%s", lab, error$message)
    )
  } else if (is.null(regexp)) {
    expect(
      !is.null(error),
      sprintf("%s did not throw an error.", lab)
    )
  } else {
    expect_match(error$message, regexp, ...)
  }
}

#' @export
#' @rdname output-expectations
expect_message <- function(object, regexp = NULL, ..., all = FALSE,
  info = NULL, label = NULL) {

  lab <- make_label(object, info = info, label = label)
  messages <- evaluate_promise(object)$messages
  n <- length(messages)
  bullets <- paste("* ", messages, collapse = "\n")

  msg <- sprintf(ngettext(n, "%d message", "%d messages"), n)

  if (identical(regexp, NA)) {
    expect(
      length(messages) == 0,
      sprintf("%s showed %s.\n%s", lab, msg, bullets)
    )
  } else if (is.null(regexp)) {
    expect(
      length(messages) > 0,
      sprintf("%s showed %s", lab, msg)
    )
  } else {
    expect_match(messages, regexp, all = all, ...)
  }
}

#' @export
#' @rdname output-expectations
expect_warning <- function(object, regexp = NULL, ..., all = FALSE,
  info = NULL, label = NULL) {

  lab <- make_label(object, info = info, label = label)
  warnings <- evaluate_promise(object)$warnings
  n <- length(warnings)
  bullets <- paste("* ", warnings, collapse = "\n")

  msg <- sprintf(ngettext(n, "%d warning", "%d warnings"), n)

  if (identical(regexp, NA)) {
    expect(
      length(warnings) == 0,
      sprintf("%s showed %s.\n%s", lab, msg, bullets)
    )
  } else if (is.null(regexp)) {
    expect(
      length(warnings) > 0,
      sprintf("%s showed %s", lab, msg)
    )
  } else {
    expect_match(warnings, regexp, all = all, ...)
  }
}

#' @export
#' @rdname output-expectations
expect_silent <- function(expr) {
  label <- find_expr("expr")
  out <- evaluate_promise(expr)

  outputs <- c(
    if (!identical(out$output, "")) "output",
    if (length(out$warnings) > 0) "warnings",
    if (length(out$messages) > 0) "messages"
  )

  expect(
    length(outputs) == 0,
    paste0(label, " produced ", paste(outputs, collapse = ", "))
  )
}