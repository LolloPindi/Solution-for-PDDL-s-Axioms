#ifndef AXIOMS_H
#define AXIOMS_H

#include "per_task_information.h"
#include "task_proxy.h"

#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

class AxiomEvaluator {
    struct AxiomRule;
    struct AxiomLiteral {
        std::vector<AxiomRule *> condition_of;
    };
    struct AxiomRule {
        int condition_count;
        int unsatisfied_conditions;
        int effect_var;
        int effect_val;
        AxiomLiteral *effect_literal;
        AxiomRule(
            int cond_count, int eff_var, int eff_val, AxiomLiteral *eff_literal)
            : condition_count(cond_count),
              unsatisfied_conditions(cond_count),
              effect_var(eff_var),
              effect_val(eff_val),
              effect_literal(eff_literal) {
        }
    };
    struct NegationByFailureInfo {
        int var_no;
        AxiomLiteral *literal;
        NegationByFailureInfo(int var, AxiomLiteral *lit)
            : var_no(var), literal(lit) {
        }
    };

    bool task_has_axioms;

    std::vector<std::vector<AxiomLiteral>> axiom_literals;
    std::vector<AxiomRule> rules;
    std::vector<std::vector<NegationByFailureInfo>> nbf_info_by_layer;
    std::vector<int> default_values;
    std::vector<const AxiomLiteral *> queue;

    template<typename Values, typename Accessor>
    void evaluate_aux(Values &values, const Accessor &accessor);

    
    std::vector<std::vector<std::string>> fact_by_value;
    std::unordered_map<std::string, int> gate_var;
    std::string eval_lp_text;
    std::string static_facts;
    std::string auto_facts;   
    std::unordered_map<std::string, std::set<std::string>> eval_cache;

    void clingo_init(const TaskProxy &task_proxy);
    void clingo_override(std::vector<int> &state);
public:
    explicit AxiomEvaluator(const TaskProxy &task_proxy);

    void evaluate(std::vector<int> &state);
};

extern PerTaskInformation<AxiomEvaluator> g_axiom_evaluators;

#endif
