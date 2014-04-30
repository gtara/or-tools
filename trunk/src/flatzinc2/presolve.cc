// Copyright 2010-2013 Google
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in comÏpliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS% IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "base/map_util.h"
#include "base/strutil.h"
#include "flatzinc2/presolve.h"

DECLARE_bool(logging);
DECLARE_bool(verbose_logging);

namespace operations_research {

// For the author's reference, here is an indicative list of presolve rules that
// should eventually be implemented.
//
// Presolve rule:
//   - array_var_int_element and index is affine -> reduce array
//   - array_int_element and index is flattened 2d -> rewrite as 2d array.
//   - table_int -> intersect variables domains with tuple set.
//
// TODO(user):
//   - store dependency graph of constraints -> variable to speed up presolve.
//   - use the same dependency graph to speed up variable substitution.
//   - add more check when presolving out a variable or a constraint.

// ----- Presolve rules -----

// constraint: int_var = cast(bool_var). The presolve substitutes the bool_var
// by the integer variable everywhere.
bool FzPresolver::PresolveBool2Int(FzConstraint* ct) {
  MarkVariablesAsEquivalent(ct->Arg(0).Var(), ct->Arg(1).Var());
  ct->MarkAsInactive();
  return true;
}

// Presolve equality constraint by substituting one variable by another if the
// equality constraint is between two variables, or by assigning the variable to
// the constant if one of the term is constant.
bool FzPresolver::PresolveIntEq(FzConstraint* ct) {
  if (ct->Arg(0).IsIntegerVariable()) {
    if (ct->Arg(1).HasOneValue()) {
      const int64 value = ct->Arg(1).Value();
      ct->Arg(0).Var()->domain.IntersectWithInterval(value, value);
      ct->MarkAsInactive();
      return true;
    } else if (ct->Arg(1).IsIntegerVariable()) {
      MarkVariablesAsEquivalent(ct->Arg(0).Var(), ct->Arg(1).Var());
      ct->MarkAsInactive();
      return true;
    }
  } else if (ct->Arg(0).HasOneValue()) {  // Arg0 is an integer value.
    const int64 value = ct->Arg(0).Value();
    if (ct->Arg(1).IsIntegerVariable()) {
      ct->Arg(1).Var()->domain.IntersectWithInterval(value, value);
      ct->MarkAsInactive();
      return true;
    } else if (ct->Arg(1).HasOneValue() && value == ct->Arg(1).Value()) {
      // No-op, removing.
      ct->MarkAsInactive();
      return false;
    }
  }
  return false;
}

// Constraint x0 != x1. Propagates if x0 or x1 is constant.
bool FzPresolver::PresolveIntNe(FzConstraint* ct) {
  if (ct->presolve_propagation_done) {
    return false;
  }
  if ((ct->Arg(0).IsIntegerVariable() && ct->Arg(1).HasOneValue() &&
       ct->Arg(0).Var()->domain.RemoveValue(ct->Arg(1).Value())) ||
      (ct->Arg(1).IsIntegerVariable() && ct->Arg(0).HasOneValue() &&
       ct->Arg(1).Var()->domain.RemoveValue(ct->Arg(0).Value()))) {
    FZVLOG << "Propagate " << ct->DebugString() << FZENDL;
    ct->MarkAsInactive();
    ct->presolve_propagation_done = true;
    return true;
  }
  return false;
}

// Presolve constraints of the form x0 OP x1 where OP is one of le, lt, ge, gt.
// It performs bound propagation.
bool FzPresolver::PresolveInequalities(FzConstraint* ct) {
  const std::string& id = ct->type;
  if (ct->Arg(0).IsIntegerVariable() && ct->Arg(1).HasOneValue()) {
    FzIntegerVariable* const var = ct->Arg(0).Var();
    const int64 value = ct->Arg(1).Value();
    if (id == "int_le") {
      var->domain.IntersectWithInterval(kint64min, value);
    } else if (id == "int_lt") {
      var->domain.IntersectWithInterval(kint64min, value - 1);
    } else if (id == "int_ge") {
      var->domain.IntersectWithInterval(value, kint64max);
    } else if (id == "int_gt") {
      var->domain.IntersectWithInterval(value + 1, kint64max);
    }
    ct->MarkAsInactive();
    return true;
  } else if (ct->Arg(0).HasOneValue() && ct->Arg(1).IsIntegerVariable()) {
    FzIntegerVariable* const var = ct->Arg(1).Var();
    const int64 value = ct->Arg(0).Value();
    if (id == "int_le") {
      var->domain.IntersectWithInterval(value, kint64max);
    } else if (id == "int_lt") {
      var->domain.IntersectWithInterval(value + 1, kint64max);
    } else if (id == "int_ge") {
      var->domain.IntersectWithInterval(kint64min, value);
    } else if (id == "int_gt") {
      var->domain.IntersectWithInterval(kint64min, value - 1);
    }
    ct->MarkAsInactive();
    return true;
  }
  return false;
}

// A reified constraint is a constraint that has been casted into a boolean
// variable that represents its status.
// Thus x == 3 can be reified into b == (x == 3).
//
// This presolve rule transforms a reified constraint into a non reified one if
// the boolean variable is a singleton.
void FzPresolver::Unreify(FzConstraint* ct) {
  const std::string& id = ct->type;
  const int last_argument = ct->arguments.size() - 1;
  ct->type.resize(id.size() - 5);
  FzIntegerVariable* const bool_var = ct->target_variable;
  if (bool_var != nullptr) {
    // DCHECK bool_var is bound
    ct->target_variable = bool_var;
    bool_var->defining_constraint = nullptr;
  }
  ct->arguments.pop_back();
  if (ct->Arg(last_argument).Value() == 1) {
    FZVLOG << "Unreify " << ct->DebugString() << FZENDL;
  } else {
    FZVLOG << "Unreify and inverse " << ct->DebugString() << FZENDL;
    if (id == "int_eq")
      ct->type = "int_ne";
    else if (id == "int_ne")
      ct->type = "int_eq";
    else if (id == "int_ge")
      ct->type = "int_lt";
    else if (id == "int_gt")
      ct->type = "int_le";
    else if (id == "int_le")
      ct->type = "int_gt";
    else if (id == "int_lt")
      ct->type = "int_ge";
    else if (id == "int_lin_eq")
      ct->type = "int_lin_ne";
    else if (id == "int_lin_ne")
      ct->type = "int_lin_eq";
    else if (id == "int_lin_ge")
      ct->type = "int_lin_lt";
    else if (id == "int_lin_gt")
      ct->type = "int_lin_le";
    else if (id == "int_lin_le")
      ct->type = "int_lin_gt";
    else if (id == "int_lin_lt")
      ct->type = "int_lin_ge";
    else if (id == "bool_eq")
      ct->type = "bool_ne";
    else if (id == "bool_ne")
      ct->type = "bool_eq";
    else if (id == "bool_ge")
      ct->type = "bool_lt";
    else if (id == "bool_gt")
      ct->type = "bool_le";
    else if (id == "bool_le")
      ct->type = "bool_gt";
    else if (id == "bool_lt")
      ct->type = "bool_ge";
  }
}

// Presolves a constraint x0 is an element of arg1.
bool FzPresolver::PresolveSetIn(FzConstraint* ct) {
  if (ct->Arg(0).IsIntegerVariable()) {
    FZVLOG << "Propagate " << ct->DebugString() << FZENDL;
    IntersectDomainWithIntArgument(&ct->Arg(0).Var()->domain, ct->Arg(1));
    ct->MarkAsInactive();
    // TODO(user): Returns true iff the intersection yielded some domain
    // reduction.
    return true;
  }
  return false;
}

// Presolves a constraint x0 * x1 = x2.
bool FzPresolver::PresolveIntTimes(FzConstraint* ct) {
  if (ct->Arg(0).HasOneValue() && ct->Arg(1).HasOneValue() &&
      ct->Arg(2).IsIntegerVariable() && !ct->presolve_propagation_done) {
    FZVLOG << " Propagate " << ct->DebugString() << FZENDL;
    const int64 value = ct->Arg(0).Value() * ct->Arg(1).Value();
    ct->presolve_propagation_done = true;
    if (ct->Arg(2).Var()->domain.Contains(value)) {
      ct->Arg(2).Var()->domain.IntersectWithInterval(value, value);
      ct->MarkAsInactive();
      return true;
    }
  }
  return false;
}

// Presolves a constraint x0 / x1 = x2.
bool FzPresolver::PresolveIntDiv(FzConstraint* ct) {
  if (ct->Arg(0).HasOneValue() && ct->Arg(1).HasOneValue() &&
      ct->Arg(2).IsIntegerVariable() && !ct->presolve_propagation_done) {
    FZVLOG << " Propagate " << ct->DebugString() << FZENDL;
    const int64 value = ct->Arg(0).Value() / ct->Arg(1).Value();
    ct->presolve_propagation_done = true;
    if (ct->Arg(2).Var()->domain.Contains(value)) {
      ct->Arg(2).Var()->domain.IntersectWithInterval(value, value);
      ct->MarkAsInactive();
      return true;
    }
  }
  return false;
}

// Forces all boolean variables to false if the or(variables) is false.
bool FzPresolver::PresolveArrayBoolOr(FzConstraint* ct) {
  if (!ct->presolve_propagation_done && ct->Arg(1).HasOneValue() &&
      ct->Arg(1).Value() == 0) {
    for (const FzIntegerVariable* const var : ct->arguments[0].variables) {
      if (!var->domain.Contains(0)) {
        return false;
      }
    }
    FZVLOG << "Propagate " << ct->DebugString() << FZENDL;
    for (FzIntegerVariable* const var : ct->arguments[0].variables) {
      var->domain.IntersectWithInterval(0, 0);
    }
    ct->presolve_propagation_done = true;
    return true;
  }
  return false;
}

// Forces all boolean variables to true if the and(variables) is true.
bool FzPresolver::PresolveArrayBoolAnd(FzConstraint* ct) {
  if (!ct->presolve_propagation_done && ct->Arg(1).HasOneValue() &&
      ct->Arg(1).Value() == 1) {
    for (const FzIntegerVariable* const var : ct->arguments[0].variables) {
      if (!var->domain.Contains(1)) {
        return false;
      }
    }
    FZVLOG << "Propagate " << ct->DebugString() << FZENDL;
    for (FzIntegerVariable* const var : ct->arguments[0].variables) {
      var->domain.IntersectWithInterval(1, 1);
    }
    ct->presolve_propagation_done = true;
    return true;
  }
  return false;
}

// Simplify b == (bool_var == false) into b != bool_var.
bool FzPresolver::PresolveBoolEqNeReif(FzConstraint* ct) {
  if (ct->Arg(1).HasOneValue()) {
    FZVLOG << "Simplify " << ct->DebugString() << FZENDL;
    const int64 value = ct->Arg(1).Value();
    // Remove boolean value argument.
    ct->arguments[1] = ct->Arg(2);
    ct->arguments.pop_back();
    // Change type.
    ct->type = ((ct->type == "bool_eq_reif" && value == 1) ||
                (ct->type == "bool_ne_reif" && value == 0))
                   ? "bool_eq"
                   : "bool_not";
    return true;
  }
  return false;
}

// Transform Sum(ai * xi) > c into Sum(ax * xi) >= c + 1.
bool FzPresolver::PresolveIntLinGt(FzConstraint* ct) {
  FZVLOG << "Transform " << ct->DebugString() << " into int_lin_ge" << FZENDL;
  CHECK_EQ(FzArgument::INT_VALUE, ct->Arg(2).type);
  ct->MutableArg(2)->values[0]++;
  ct->type = "int_lin_ge";
  return true;
}

// Transform Sum(ai * xi) < c into Sum(ax * xi) <= c - 1.
bool FzPresolver::PresolveIntLinLt(FzConstraint* ct) {
  FZVLOG << "Transform " << ct->DebugString() << " into int_lin_le" << FZENDL;
  CHECK_EQ(FzArgument::INT_VALUE, ct->Arg(2).type);
  ct->MutableArg(2)->values[0]--;
  ct->type = "int_lin_le";
  return true;
}

// If x = A[y], with A an integer array, then the domain of x is included in A.
bool FzPresolver::PresolveArrayIntElement(FzConstraint* ct) {
  if (ct->Arg(2).IsIntegerVariable() && !ct->presolve_propagation_done) {
    FZVLOG << "Propagate domain on " << ct->DebugString() << FZENDL;
    IntersectDomainWithIntArgument(&ct->Arg(2).Var()->domain, ct->Arg(1));
    ct->presolve_propagation_done = true;
    return true;
  }
  return false;
}

// The minizinc to flatzinc presolve transforms x + 2 y >= 3 into -x -2y <= -3.
// Reverse the constraint to get the original >=. This is true for ==, !=, <=,
// <, >, >= and their reified versions.
bool FzPresolver::PresolveLinear(FzConstraint* ct) {
  if (ct->arguments[0].values.empty()) {
    return false;
  }
  for (const int64 coef : ct->arguments[0].values) {
    if (coef > 0) {
      return false;
    }
  }
  FZVLOG << "Reverse " << ct->DebugString() << FZENDL;
  for (int64& coef : ct->arguments[0].values) {
    coef *= -1;
  }
  ct->MutableArg(2)->values[0] *= -1;
  const std::string& id = ct->type;
  if (id == "int_lin_le") {
    ct->type = "int_lin_ge";
  } else if (id == "int_lin_lt") {
    ct->type = "int_lin_gt";
  } else if (id == "int_lin_le") {
    ct->type = "int_lin_ge";
  } else if (id == "int_lin_lt") {
    ct->type = "int_lin_gt";
  } else if (id == "int_lin_le_reif") {
    ct->type = "int_lin_ge_reif";
  } else if (id == "int_lin_ge_reif") {
    ct->type = "int_lin_le_reif";
  }
  return true;
}

// If a scal prod only contains positive constant and variables, then we
// can propagate an upper bound on all variables.
bool FzPresolver::PresolvePropagatePositiveLinear(FzConstraint* ct) {
  const int64 rhs = ct->Arg(2).Value();
  if (ct->presolve_propagation_done || rhs < 0) {
    return false;
  }
  for (const int64 coef : ct->arguments[0].values) {
    if (coef < 0) {
      return false;
    }
  }
  for (FzIntegerVariable* const var : ct->Arg(1).variables) {
    if (!var->domain.is_interval || var->domain.values.empty() ||
        var->domain.values[0] < 0) {
      return false;
    }
  }
  for (int i = 0; i < ct->arguments[0].values.size(); ++i) {
    const int64 coef = ct->arguments[0].values[i];
    if (coef > 0) {
      FzIntegerVariable* const var = ct->Arg(1).variables[i];
      var->domain.IntersectWithInterval(0, rhs / coef);
    }
  }
  ct->presolve_propagation_done = true;
  return true;
}

// Minizinc flattens 2d element constraints (x = A[y][z]) into 1d element
// constraint with an affine mapping between y, z and the new index.
// This rule stores the mapping to reconstruct the 2d element constraint.
bool FzPresolver::PresolveStoreMapping(FzConstraint* ct) {
  if (ct->arguments[0].values.size() == 2 &&
      ct->Arg(1).variables[0] == ct->target_variable &&
      ct->arguments[0].values[0] == -1 &&
      !ContainsKey(affine_map_, ct->Arg(1).variables[0]) &&
      ct->strong_propagation) {
    affine_map_[ct->Arg(1).variables[0]] =
        AffineMapping(ct->Arg(1).variables[1], ct->arguments[0].values[1],
                      -ct->Arg(2).Value(), ct);
    FZVLOG << "Store affine mapping info for " << ct->DebugString() << FZENDL;
    return true;
  }
  return false;
}

// Reconstructs the 2d element constraint in case the mapping only contains 1
// variable. (e.g. x = A[2][y]).
bool FzPresolver::PresolveSimplifyElement(FzConstraint* ct) {
  FzIntegerVariable* const index_var = ct->Arg(0).Var();
  if (ContainsKey(affine_map_, index_var)) {
    const AffineMapping& mapping = affine_map_[index_var];
    const FzDomain& domain = mapping.variable->domain;
    if (!domain.is_interval || domain.values.size() != 2 ||
        domain.values[0] < 0 || mapping.offset < 0) {
      // Invalid case. Ignore it.
      return false;
    }
    const std::vector<int64>& values = ct->Arg(1).values;
    std::vector<int64> new_values;
    for (int64 i = domain.values[0]; i <= domain.values[1]; ++i) {
      const int64 index = (i - 1) * mapping.coefficient + mapping.offset;
      if (index < 0) {
        return false;
      }
      if (index >= values.size()) {
        break;
      }
      new_values.push_back(values[index]);
    }
    // Rewrite constraint.
    FZVLOG << "Simplify " << ct->DebugString() << FZENDL;
    ct->arguments[0].variables[0] = mapping.variable;
    // TODO(user): Encapsulate argument setters.
    ct->MutableArg(1)->values.swap(new_values);
    if (ct->Arg(1).values.size() == 1) {
      ct->MutableArg(1)->type = FzArgument::INT_VALUE;
    }
    // Reset propagate flag.
    ct->presolve_propagation_done = false;
    FZVLOG << "    into  " << ct->DebugString() << FZENDL;
    // Mark old index var and affine constraint as presolved out.
    mapping.constraint->active = false;
    index_var->active = false;
    return true;
  }
  if (index_var->domain.is_interval && index_var->domain.values.size() == 2 &&
      index_var->domain.values[1] < ct->Arg(1).values.size()) {
    // Reduce array of values.
    ct->MutableArg(1)->values.resize(index_var->domain.values[1]);
    ct->presolve_propagation_done = false;
    FZVLOG << "Reduce array on " << ct->DebugString() << FZENDL;
    return true;
  }
  return false;
}

// Main presolve rule caller.
bool FzPresolver::PresolveOneConstraint(FzConstraint* ct) {
  bool changed = false;
  const std::string& id = ct->type;
  const int num_arguments = ct->arguments.size();
  if (HasSuffixString(id, "_reif") &&
      ct->Arg(num_arguments - 1).HasOneValue()) {
    Unreify(ct);
    changed = true;
  }
  if (id == "bool2int") changed |= PresolveBool2Int(ct);
  if (id == "int_le" || id == "int_lt" || id == "int_ge" || id == "int_gt") {
    changed |= PresolveInequalities(ct);
  }
  if (id == "int_abs" && !ContainsKey(abs_map_, ct->Arg(1).Var())) {
    // Stores abs() map.
    FZVLOG << "Stores abs map for " << ct->DebugString() << FZENDL;
    abs_map_[ct->Arg(1).Var()] = ct->Arg(0).Var();
    changed = true;
  }
  if ((id == "int_eq_reif" || id == "int_ne_reif" || id == "int_ne") &&
      ct->Arg(1).HasOneValue() && ct->Arg(1).Value() == 0 &&
      ContainsKey(abs_map_, ct->Arg(0).Var())) {
    FZVLOG << "Remove abs() from " << ct->DebugString() << FZENDL;
    ct->arguments[0].variables[0] = abs_map_[ct->Arg(0).Var()];
    changed = true;
  }
  if (id == "int_eq") changed |= PresolveIntEq(ct);
  if (id == "int_ne") changed |= PresolveIntNe(ct);
  if (id == "set_in") changed |= PresolveSetIn(ct);
  if (id == "array_bool_and") changed |= PresolveArrayBoolAnd(ct);
  if (id == "array_bool_or") changed |= PresolveArrayBoolOr(ct);
  if (id == "bool_eq_reif" || id == "bool_ne_reif") {
    changed |= PresolveBoolEqNeReif(ct);
  }
  if (id == "int_div") changed |= PresolveIntDiv(ct);
  if (id == "int_times") changed |= PresolveIntTimes(ct);
  if (id == "int_lin_gt") changed |= PresolveIntLinGt(ct);
  if (id == "int_lin_lt") changed |= PresolveIntLinLt(ct);
  if (HasPrefixString(id, "int_lin_")) changed |= PresolveLinear(ct);
  if (id == "int_lin_eq" || id == "int_lin_le") {
    changed |= PresolvePropagatePositiveLinear(ct);
  }
  if (id == "int_lin_eq") changed |= PresolveStoreMapping(ct);
  if (id == "array_int_element") {
    changed |= PresolveSimplifyElement(ct);
    changed |= PresolveArrayIntElement(ct);
  }
  return changed;
}

bool FzPresolver::Run(FzModel* model) {
  bool changed_since_start = false;
  for (;;) {
    bool changed = false;
    var_representative_map_.clear();
    for (FzConstraint* const ct : model->constraints()) {
      if (ct->active) {
        changed |= PresolveOneConstraint(ct);
      }
    }
    if (!var_representative_map_.empty()) {
      // Some new substitutions were introduced. Let's process them.
      DCHECK(changed);
      changed = true;  // To be safe in opt mode.
      SubstituteEverywhere(model);
      var_representative_map_.clear();
    }
    changed_since_start |= changed;
    if (!changed) break;
  }
  return changed_since_start;
}

// ----- Substitution support -----

void FzPresolver::MarkVariablesAsEquivalent(FzIntegerVariable* from,
                                            FzIntegerVariable* to) {
  CHECK(from != nullptr);
  CHECK(to != nullptr);
  // Apply the substitutions, if any.
  from = FindRepresentativeOfVar(from);
  to = FindRepresentativeOfVar(to);
  if (to->temporary) {
    // Let's switch to keep a non temporary as representative.
    FzIntegerVariable* tmp = to;
    to = from;
    from = tmp;
  }
  if (from != to) {
    FZVLOG << "Mark " << from->DebugString() << " as equivalent to "
           << to->DebugString() << FZENDL;
    CHECK(to->Merge(from->name, from->domain, from->defining_constraint,
                    from->temporary));
    from->active = false;
    var_representative_map_[from] = to;
  }
}

FzIntegerVariable* FzPresolver::FindRepresentativeOfVar(
    FzIntegerVariable* var) {
  if (var == nullptr) return nullptr;
  FzIntegerVariable* start_var = var;
  // First loop: find the top parent.
  for (;;) {
    FzIntegerVariable* parent =
        FindWithDefault(var_representative_map_, var, var);
    if (parent == var) break;
    var = parent;
  }
  // Second loop: attach all the path to the top parent.
  while (start_var != var) {
    FzIntegerVariable* const parent = var_representative_map_[start_var];
    var_representative_map_[start_var] = var;
    start_var = parent;
  }
  return FindWithDefault(var_representative_map_, var, var);
}

void FzPresolver::SubstituteEverywhere(FzModel* model) {
  // Rewrite the constraints.
  for (FzConstraint* const ct : model->constraints()) {
    if (ct != nullptr && ct->active) {
      for (int i = 0; i < ct->arguments.size(); ++i) {
        FzArgument* argument = &ct->arguments[i];
        switch (argument->type) {
          case FzArgument::INT_VAR_REF:
          case FzArgument::INT_VAR_REF_ARRAY: {
            for (int i = 0; i < argument->variables.size(); ++i) {
              argument->variables[i] =
                  FindRepresentativeOfVar(argument->variables[i]);
            }
            break;
          }
          default: {}
        }
      }
      ct->target_variable = FindRepresentativeOfVar(ct->target_variable);
    }
  }
  // Rewrite the search.
  for (FzAnnotation* const ann : model->mutable_search_annotations()) {
    SubstituteAnnotation(ann);
  }
  // Rewrite the output.
  for (FzOnSolutionOutput* const output : model->mutable_output()) {
    output->variable = FindRepresentativeOfVar(output->variable);
    for (int i = 0; i < output->flat_variables.size(); ++i) {
      output->flat_variables[i] =
          FindRepresentativeOfVar(output->flat_variables[i]);
    }
  }
  // Do not forget to merge domain that could have evolved asynchronously
  // during presolve.
  for (const auto& iter : var_representative_map_) {
    iter.second->domain.IntersectWithFzDomain(iter.first->domain);
  }
}

void FzPresolver::SubstituteAnnotation(FzAnnotation* ann) {
  // TODO(user): Remove recursion.
  switch (ann->type) {
    case FzAnnotation::ANNOTATION_LIST:
    case FzAnnotation::FUNCTION_CALL: {
      for (int i = 0; i < ann->annotations.size(); ++i) {
        SubstituteAnnotation(&ann->annotations[i]);
      }
      break;
    }
    case FzAnnotation::INT_VAR_REF: {
      ann->variable = FindRepresentativeOfVar(ann->variable);
      break;
    }
    case FzAnnotation::INT_VAR_REF_ARRAY: {
      for (int i = 0; i < ann->variables.size(); ++i) {
        ann->variables[i] = FindRepresentativeOfVar(ann->variables[i]);
      }
      break;
    }
    default: {}
  }
}

// ----- Helpers -----

void FzPresolver::IntersectDomainWithIntArgument(FzDomain* domain,
                                                 const FzArgument& arg) {
  switch (arg.type) {
    case FzArgument::INT_VALUE: {
      const int64 value = arg.Value();
      domain->IntersectWithInterval(value, value);
      break;
    }
    case FzArgument::INT_INTERVAL: {
      domain->IntersectWithInterval(arg.values[0], arg.values[1]);
      break;
    }
    case FzArgument::INT_LIST: {
      domain->IntersectWithListOfIntegers(arg.values);
      break;
    }
    default: { LOG(FATAL) << "Wrong domain type" << arg.DebugString(); }
  }
}

// ----- Clean up model -----

namespace {
void Regroup(FzConstraint* start, const std::vector<FzIntegerVariable*>& chain,
             const std::vector<FzIntegerVariable*>& carry_over) {
  // End of chain, reconstruct.
  FzIntegerVariable* const out = carry_over.back();
  start->arguments.pop_back();
  start->arguments[0].variables[0] = out;
  start->MutableArg(1)->type = FzArgument::INT_VAR_REF_ARRAY;
  start->MutableArg(1)->variables = chain;
  const std::string old_type = start->type;
  start->type = start->type == "int_min" ? "minimum_int" : "maximum_int";
  start->target_variable = out;
  out->defining_constraint = start;
  for (FzIntegerVariable* const var : carry_over) {
    if (var != carry_over.back()) {
      var->active = false;
    }
  }
  FZVLOG << "Regroup chain of " << old_type << " into " << start->DebugString()
         << FZENDL;
}

void CheckRegroupStart(FzConstraint* ct, FzConstraint** start,
                       std::vector<FzIntegerVariable*>* chain,
                       std::vector<FzIntegerVariable*>* carry_over) {
  if ((ct->type == "int_min" || ct->type == "int_max") &&
      ct->Arg(0).Var() == ct->Arg(0).Var()) {
    // This is the start of the chain.
    *start = ct;
    chain->push_back(ct->Arg(0).Var());
    carry_over->push_back(ct->Arg(2).Var());
    carry_over->back()->defining_constraint = nullptr;
  }
}
}  // namespace

void FzPresolver::CleanUpModelForTheCpSolver(FzModel* model) {
  // First pass.
  for (FzConstraint* const ct : model->constraints()) {
    const std::string& id = ct->type;
    // Remove ignored annotations on int_lin_eq.
    if (id == "int_lin_eq") {
      if (ct->arguments[0].values.size() > 2 &&
          ct->target_variable != nullptr) {
        ct->RemoveTargetVariable();
        continue;
      } else if (ct->arguments[0].values.size() > 2 &&
                 ct->strong_propagation) {
        FZVLOG << "Remove strong_propagation from " << ct->DebugString()
               << FZENDL;
        ct->strong_propagation = false;
        continue;
      }
    }
    // Remove target variables from constraints passed to SAT.
    if (ct->target_variable != nullptr &&
        (id == "array_bool_and" || id == "array_bool_or" ||
         id == "bool_eq_reif" || id == "bool_ne_reif" || id == "bool_le_reif" ||
         id == "bool_ge_reif")) {
      ct->RemoveTargetVariable();
    }
  }
  // Second pass.
  for (FzConstraint* const ct : model->constraints()) {
    const std::string& id = ct->type;
    // Create new target variables with unused boolean variables.
    if (ct->target_variable == nullptr &&
        (id == "int_lin_eq_reif" || id == "int_lin_ne_reif" ||
         id == "int_lin_ge_reif" || id == "int_lin_le_reif" ||
         id == "int_lin_gt_reif" || id == "int_lin_lt_reif" ||
         id == "int_eq_reif" || id == "int_ne_reif" || id == "int_le_reif" ||
         id == "int_ge_reif" || id == "int_lt_reif" || id == "int_gt_reif")) {
      FzIntegerVariable* const bool_var = ct->Arg(2).Var();
      if (bool_var != nullptr && bool_var->defining_constraint == nullptr) {
        FZVLOG << "Create target_variable on " << ct->DebugString() << FZENDL;
        ct->target_variable = bool_var;
        bool_var->defining_constraint = ct;
      }
    }
  }
  // Regroup int_min and int_max into maximum_int and maximum_int.
  // The minizinc to flatzinc expander will transform x = std::max([v1, .., vn])
  // into:
  //   tmp1 = std::max(v1, v1)
  //   tmp2 = std::max(v2, tmp1)
  //   tmp3 = std::max(v3, tmp2)
  // ...
  // This code reconstructs the initial std::min(array) or std::max(array).
  FzConstraint* start = nullptr;
  std::vector<FzIntegerVariable*> chain;
  std::vector<FzIntegerVariable*> carry_over;
  for (FzConstraint* const ct : model->constraints()) {
    if (start == nullptr) {
      CheckRegroupStart(ct, &start, &chain, &carry_over);
    } else if (ct->type == start->type &&
               ct->Arg(1).Var() == carry_over.back()) {
      chain.push_back(ct->Arg(0).Var());
      carry_over.push_back(ct->Arg(2).Var());
      ct->active = false;
      ct->target_variable = nullptr;
      carry_over.back()->defining_constraint = nullptr;
    } else {
      Regroup(start, chain, carry_over);
      // Clean
      start = nullptr;
      chain.clear();
      carry_over.clear();
      // Check again ct.
      CheckRegroupStart(ct, &start, &chain, &carry_over);
    }
  }
  // Checks left over from the loop.
  if (start != nullptr) {
    Regroup(start, chain, carry_over);
  }
}
}  // namespace operations_research