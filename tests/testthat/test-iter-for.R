context("iter-for")

test_that("can iterate() with iterators", {
  iter <- as_iterator(1:3)
  out <- int()

  iterate(for (x in iter) {
    out <- c(out, x)
  })
  expect_identical(out, 1:3)
})

test_that("can use break within iterate()", {
  out <- int()
  bool <- FALSE

  iterate(for (x in 1:3) {
    out <- c(out, x)
    if (bool) {
      break
    }
    bool <- TRUE
  })

  expect_identical(out, 1:2)
})

test_that("can use next within iterate()", {
  out <- int()
  bool <- FALSE

  iterate(for (x in 1:3) {
    if (bool) {
      next
    } else {
      out <- c(out, x)
    }
    bool <- TRUE
  })

  expect_identical(out, 1L)
})

test_that("can iterate with a non-block expression", {
  iter <- as_iterator(1:3)
  out <- int()

  iterate(for (x in iter) out <- c(out, x))
  expect_identical(out, 1:3)
})

test_that("iterating with a done iterator cause an error", {
  iter <- gen("foo")
  iterate(for (x in iter) x)
  expect_error(iterate(for (x in iter) x), "is done")
})

test_that("iterating works when flowery is not loaded", {
  new_env <- new.env(parent = baseenv())

  eval(
    quote(flowery::iterate(for (x in flowery::as_iterator(1:3)) x)),
    new_env
  )

  expect_equal(new_env[["x"]], 3)
})

