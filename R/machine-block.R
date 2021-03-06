
block_parts <- function(expr) {
  parts <- node_list_parts(node_cdr(expr))

  if (is_null(parts)) {
    NULL
  } else {
    push_goto(node_list_tail_car(parts))
    parts
  }
}

node_list_parts <- function(node) {
  rest <- node
  parts <- NULL
  parent <- NULL

  has_future <- function() {
    !is_null(node_cdr(rest))
  }
  has_past <- function() {
    !is_null(parent)
  }

  while (!is_null(rest)) {
    expr <- node_car(rest)

    if (is_pause(expr)) {
      # If pause has no future we don't know which state it should
      # resume to. We register it so the state can be adjusted later.
      if (has_future()) {
        pause_lang <- new_pause(poke_state(), node_cdr(expr))
        pause_node <- pairlist(pause_lang)
      } else {
        pause_lang <- new_pause(peek_state(), node_cdr(expr))
        pause_node <- pairlist(pause_lang)
        push_pause_node(pause_node)
      }

      if (has_past()) {
        node_poke_cdr(parent, pause_node)
        pause_block <- new_block(node)
      } else {
        pause_block <- new_block(pause_node)
      }
      parts <- node_list_poke_cdr(parts, pairlist(pause_block))

      rest <- node <- node_cdr(rest)
      parent <- NULL
      next
    }

    # Extract nested states. If there is a continuation, pass on the
    # relevant goto and pause nodes. Fill those nodes only when we
    # extracted the parts so they get the right state index.
    if (has_future()) {
      next_goto <- node(goto_lang(-1L), NULL)
      pauses <- null_node()

      with_jump_nodes(next_goto, pauses, has_past(), {
        nested_parts <- expr_parts(expr)
      })

      if (!is_null(nested_parts)) {
        # Empty blocks occur when a translator returns a separate
        # state that shouldn't be appended to the current past.
        # In this case, poke state one more time.
        state <- poke_state()
        if (is_separate_state(nested_parts)) {
          state <- poke_state()
        }
        node_poke_car(next_goto, goto_lang(state))
        pauses_push_state(pauses, state)
      }
    } else {
      nested_parts <- expr_parts(expr)
    }

    if (is_null(nested_parts)) {
      parent <- rest
      rest <- node_cdr(rest)
      next
    }

    # If we found nested states, check if there are any past
    # expressions to add them before the pausing block.
    pausing_part <- node_car(nested_parts)

    if (has_past()) {
      if (is_spliceable(pausing_part)) {
        pausing_part <- node_cdr(pausing_part)
      } else {
        pausing_part <- pairlist(pausing_part)
      }

      node_poke_cdr(parent, pausing_part)
      node_poke_car(nested_parts, new_block(node))
    } else {
      poke_attr(pausing_part, "spliceable", NULL)
    }

    # Merge nested states
    parts <- node_list_poke_cdr(parts, nested_parts)

    rest <- node <- node_cdr(rest)
    parent <- NULL
    next
  }

  if (is_null(parts)) {
    return(NULL)
  }

  # `node` may be NULL if there is no expression after a pause
  if (!is_null(node)) {
    remaining <- new_block(node)
    node_list_poke_cdr(parts, pairlist(remaining))
  }

  parts
}

is_exiting_block <- function(x) {
  if (!is_named_language(x)) {
    return(FALSE)
  }

  head <- as_string(node_car(x))

  switch(head,
    `if` = {
      if (!is_exiting_block(if_branch_true(x))) {
        return(FALSE)
      }
      is_exiting_block(if_branch_else(x))
    },

    `{`  = {
      last <- node_car(node_list_tail(x))
      is_exiting_block(last)
    },

    is_call(x, exiting_syms)
  )
}
exiting_syms <- list(return_sym, pause_sym, goto_sym)
