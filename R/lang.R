
lang_has <- function(lang, is_element) {
  if (!is_call(lang)) {
    return(FALSE)
  }
  if (is_element(lang)) {
    return(TRUE)
  }

  rest <- lang
  while (!is_null(rest)) {
    if (lang_has(node_car(rest), is_element)) {
      return(TRUE)
    }
    rest <- node_cdr(rest)
  }

  FALSE
}

is_named_language <- function(x) {
  is_call(x) && is_symbol(node_car(x))
}

as_exprs_node <- function(expr) {
  if (is_pairlist(expr)) {
    expr
  } else if (is_call(expr, quote(`{`))) {
    node_cdr(expr) %||% pairlist(NULL)
  } else {
    node(expr, NULL)
  }
}

pause_lang <- function(idx, ...) {
  call2("_pause", as.character(idx), ...)
}
goto_lang <- function(idx) {
  call2("_goto", as.character(idx))
}
return_lang <- function(...) {
  call2(return_sym, ...)
}
return_state_lang <- function(...) {
  call2(return_state_sym, ...)
}

new_pause <- function(state, cdr = NULL) {
  args <- node(as.character(state), cdr)
  new_language(pause_sym, args)
}

block <- function(...) {
  call2(block_sym, ...)
}
new_block <- function(x) {
  new_language(block_sym, x)
}
is_block <- function(x) {
  is_call(x, block_sym)
}
as_block <- function(x) {
  if (is_block(x)) {
    x
  } else {
    block(x)
  }
}

spliceable <- function(x) {
  poke_attr(x, "spliceable", TRUE)
  x
}
is_spliceable <- function(x) {
  is_true(attr(x, "spliceable"))
}

is_separate_state <- function(x) {
  head <- node_car(x)
  is_block(head) && is_spliceable(head) && is_null(node_cdr(head))
}

yield_lang <- function(...) {
  call2(yield_sym, ...)
}
if_lang <- function(...) {
  call2(if_sym, ...)
}
repeat_lang <- function(...) {
  call2(repeat_sym, ...)
}
while_lang <- function(...) {
  call2(while_sym, ...)
}
for_lang <- function(...) {
  call2(for_sym, ...)
}
break_lang <- function() {
  call2(break_sym)
}
next_lang <- function() {
  call2(next_sym)
}

if_branch_true <- function(expr) {
  node_car(node_cddr(expr))
}
if_branch_else <- function(expr) {
  node_cadr(node_cddr(expr))
}

for_iter_sym <- function(i) {
  sym(paste0("_for_iter_", i))
}

return_sym <- quote(`return`)
yield_sym <- quote(`yield`)

return_state_sym <- quote(`return`)
pause_sym <- quote(`_pause`)
goto_sym <- quote(`_goto`)

if_sym <- quote(`if`)
repeat_sym <- quote(`repeat`)
while_sym <- quote(`while`)
for_sym <- quote(`for`)
ctrl_syms <- list(if_sym, repeat_sym, while_sym, for_sym)
assignment_sym <- quote(`<-`)
block_sym <- quote(`{`)
switch_sym <- quote(`switch`)

break_sym <- quote(`break`)
next_sym <- quote(`next`)
loop_ctrl_syms <- list(break_sym, next_sym)
