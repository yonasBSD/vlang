// vtest build: !linux
module markused

import v2.ast
import v2.token
import v2.types

fn pos(id int) token.Pos {
	return token.Pos{
		offset: id
		id:     id
	}
}

fn test_mark_used_tracks_transitive_function_calls() {
	mut env := types.Environment.new()
	files := [
		ast.File{
			mod:   'main'
			name:  'main.v'
			stmts: [
				ast.Stmt(ast.FnDecl{
					name:  'main'
					typ:   ast.FnType{}
					pos:   pos(1)
					stmts: [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.Ident{
									name: 'foo'
									pos:  pos(2)
								}
								pos: pos(2)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					name:  'foo'
					typ:   ast.FnType{}
					pos:   pos(3)
					stmts: [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.Ident{
									name: 'bar'
									pos:  pos(4)
								}
								pos: pos(4)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					name: 'bar'
					typ:  ast.FnType{}
					pos:  pos(5)
				}),
				ast.Stmt(ast.FnDecl{
					name: 'dead'
					typ:  ast.FnType{}
					pos:  pos(6)
				}),
			]
		},
	]
	used := mark_used(files, env)
	main_key := decl_key('main', files[0].stmts[0] as ast.FnDecl, env)
	foo_key := decl_key('main', files[0].stmts[1] as ast.FnDecl, env)
	bar_key := decl_key('main', files[0].stmts[2] as ast.FnDecl, env)
	dead_key := decl_key('main', files[0].stmts[3] as ast.FnDecl, env)
	assert used[main_key]
	assert used[foo_key]
	assert used[bar_key]
	assert !used[dead_key]
}

fn test_mark_used_tracks_method_calls_with_env_types() {
	mut env := types.Environment.new()
	env.set_expr_type(12, types.Struct{
		name: 'Widget'
	})
	files := [
		ast.File{
			mod:   'main'
			name:  'main.v'
			stmts: [
				ast.Stmt(ast.FnDecl{
					name:  'main'
					typ:   ast.FnType{}
					pos:   pos(10)
					stmts: [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.SelectorExpr{
									lhs: ast.Ident{
										name: 'w'
										pos:  pos(12)
									}
									rhs: ast.Ident{
										name: 'ping'
										pos:  pos(13)
									}
									pos: pos(13)
								}
								pos: pos(13)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'w'
						typ:  ast.Ident{
							name: 'Widget'
							pos:  pos(14)
						}
						pos:  pos(14)
					}
					name:      'ping'
					typ:       ast.FnType{}
					pos:       pos(15)
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'w'
						typ:  ast.Ident{
							name: 'Widget'
							pos:  pos(16)
						}
						pos:  pos(16)
					}
					name:      'unused'
					typ:       ast.FnType{}
					pos:       pos(17)
				}),
			]
		},
	]
	used := mark_used(files, env)
	main_key := decl_key('main', files[0].stmts[0] as ast.FnDecl, env)
	ping_key := decl_key('main', files[0].stmts[1] as ast.FnDecl, env)
	unused_key := decl_key('main', files[0].stmts[2] as ast.FnDecl, env)
	assert used[main_key]
	assert used[ping_key]
	assert !used[unused_key]
}

fn test_mark_used_tracks_transformed_generic_method_calls() {
	mut env := types.Environment.new()
	env.set_expr_type(32, types.Struct{
		name: 'FlagMapper'
	})
	env.generic_types['FlagMapper.build_schema[T]'] = [
		{
			'T': types.Type(types.Struct{
				name: 'TestSchema'
			})
		},
	]
	files := [
		ast.File{
			mod:   'ownflag'
			name:  'ownflag_test.v'
			stmts: [
				ast.Stmt(ast.FnDecl{
					name:  'test_parse'
					typ:   ast.FnType{}
					pos:   pos(30)
					stmts: [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.SelectorExpr{
									lhs: ast.Ident{
										name: 'fm'
										pos:  pos(32)
									}
									rhs: ast.Ident{
										name: 'parse_T_ownflag_TestSchema'
										pos:  pos(33)
									}
									pos: pos(33)
								}
								pos: pos(33)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'fm'
						typ:  ast.Ident{
							name: 'FlagMapper'
							pos:  pos(34)
						}
						pos:  pos(34)
					}
					name:      'parse'
					typ:       ast.FnType{
						generic_params: [
							ast.Expr(ast.Ident{
								name: 'T'
								pos:  pos(35)
							}),
						]
					}
					pos:       pos(36)
					stmts:     [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.SelectorExpr{
									lhs: ast.Ident{
										name: 'fm'
										pos:  pos(37)
									}
									rhs: ast.Ident{
										name: 'reset_state'
										pos:  pos(38)
									}
									pos: pos(38)
								}
								pos: pos(38)
							}
						}),
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.SelectorExpr{
									lhs: ast.Ident{
										name: 'fm'
										pos:  pos(41)
									}
									rhs: ast.Ident{
										name: 'build_schema_T_ownflag_TestSchema'
										pos:  pos(42)
									}
									pos: pos(42)
								}
								pos: pos(42)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'fm'
						typ:  ast.Ident{
							name: 'FlagMapper'
							pos:  pos(39)
						}
						pos:  pos(39)
					}
					name:      'reset_state'
					typ:       ast.FnType{}
					pos:       pos(40)
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'fm'
						typ:  ast.Ident{
							name: 'FlagMapper'
							pos:  pos(43)
						}
						pos:  pos(43)
					}
					name:      'build_schema'
					typ:       ast.FnType{
						generic_params: [
							ast.Expr(ast.Ident{
								name: 'T'
								pos:  pos(44)
							}),
						]
					}
					pos:       pos(45)
				}),
			]
		},
	]
	used := mark_used(files, env)
	test_key := decl_key('ownflag', files[0].stmts[0] as ast.FnDecl, env)
	parse_key := decl_key('ownflag', files[0].stmts[1] as ast.FnDecl, env)
	reset_key := decl_key('ownflag', files[0].stmts[2] as ast.FnDecl, env)
	build_schema_key := decl_key('ownflag', files[0].stmts[3] as ast.FnDecl, env)
	assert used[test_key]
	assert used[parse_key]
	assert used[reset_key]
	assert used[build_schema_key]
}

fn test_mark_used_tracks_lifetime_generic_receiver_body_dependencies() {
	mut env := types.Environment.new()
	files := [
		ast.File{
			mod:   'globset'
			name:  'glob.v'
			stmts: [
				ast.Stmt(ast.StructDecl{
					name: 'GlobBuilder'
				}),
				ast.Stmt(ast.StructDecl{
					name: 'Tokens'
				}),
				ast.Stmt(ast.FnDecl{
					name:  'test_build'
					typ:   ast.FnType{}
					pos:   pos(50)
					stmts: [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.Ident{
									name: 'globset__GlobBuilder__build'
									pos:  pos(51)
								}
								pos: pos(51)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					receiver:  ast.Parameter{
						name: 'builder'
						typ:  ast.Type(ast.GenericType{
							name:   ast.Expr(ast.Ident{
								name: 'GlobBuilder'
								pos:  pos(52)
							})
							params: [
								ast.Expr(ast.LifetimeExpr{
									name: 'a'
									pos:  pos(53)
								}),
							]
						})
						pos:  pos(52)
					}
					name:      'build'
					typ:       ast.FnType{}
					pos:       pos(54)
					stmts:     [
						ast.Stmt(ast.ExprStmt{
							expr: ast.CallExpr{
								lhs: ast.SelectorExpr{
									lhs: ast.Ident{
										name: 'Tokens'
										pos:  pos(55)
									}
									rhs: ast.Ident{
										name: 'default'
										pos:  pos(56)
									}
									pos: pos(56)
								}
								pos: pos(56)
							}
						}),
					]
				}),
				ast.Stmt(ast.FnDecl{
					is_method: true
					is_static: true
					receiver:  ast.Parameter{
						typ: ast.Ident{
							name: 'Tokens'
							pos:  pos(57)
						}
						pos: pos(57)
					}
					name:      'default'
					typ:       ast.FnType{}
					pos:       pos(58)
				}),
			]
		},
	]
	used := mark_used(files, env)
	test_key := decl_key('globset', files[0].stmts[2] as ast.FnDecl, env)
	build_key := decl_key('globset', files[0].stmts[3] as ast.FnDecl, env)
	default_key := decl_key('globset', files[0].stmts[4] as ast.FnDecl, env)
	assert used[test_key]
	assert used[build_key]
	assert used[default_key]
}

fn test_mark_used_keeps_all_functions_when_no_entry_root_exists() {
	mut env := types.Environment.new()
	files := [
		ast.File{
			mod:   'mylib'
			name:  'lib.v'
			stmts: [
				ast.Stmt(ast.FnDecl{
					name: 'a'
					typ:  ast.FnType{}
					pos:  pos(21)
				}),
				ast.Stmt(ast.FnDecl{
					name: 'b'
					typ:  ast.FnType{}
					pos:  pos(22)
				}),
			]
		},
	]
	used := mark_used(files, env)
	a_key := decl_key('mylib', files[0].stmts[0] as ast.FnDecl, env)
	b_key := decl_key('mylib', files[0].stmts[1] as ast.FnDecl, env)
	assert used[a_key]
	assert used[b_key]
}
