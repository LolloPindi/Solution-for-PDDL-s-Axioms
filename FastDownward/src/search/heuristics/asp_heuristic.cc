#include "asp_heuristic.h"

#include "../plugins/plugin.h"
#include "../task_utils/task_properties.h"
#include "../utils/asp_fact_converter.h"
#include "../task_proxy.h"
#include "../utils/logging.h"

using namespace std;

namespace asp_heuristic{
    ASPHeuristic::ASPHeuristic(
                const shared_ptr<Heuristic> &heuristic, 
                const string &lp_file,
                const shared_ptr<AbstractTask> &transform, 
                bool cache_estimates,
                const string &description, 
                utils::Verbosity verbosity):Heuristic(transform, cache_estimates, description, verbosity), 
                heuristic(heuristic),
                lp_file(lp_file){

                    if(log.is_at_least_debug())
                        log << "Initializing ASP-based heuristic..."<<endl;
                    
                    // Static loading
                    ctrl.load(ASP_TYPES_FILENAME.c_str());
                    ctrl.load(lp_file.c_str());

                    // Static grounding
                    ctrl.ground({{"base", {}}});
                }
    
    int ASPHeuristic::compute_heuristic(const State &ancestor_state){
        vector<Clingo::SymbolicLiteral> current_assumptions;  
        
        //TODO[asp] put into another method
        ancestor_state.unpack();
        VariablesProxy vars = ancestor_state.get_task().get_variables();

        for(VariableProxy var: vars){
            FactProxy fact = ancestor_state[var.get_id()];

            string asp_fact = utils::atom_to_asp(fact.get_name());
            if (asp_fact.empty()) continue; 

            Clingo::Symbol symbol = Clingo::parse_term(asp_fact.c_str());
            current_assumptions.push_back(Clingo::SymbolicLiteral(symbol,true));
        }
        
        //It's time to SOLVE :)
        bool sat = false;
        auto solve_handle = ctrl.solve(Clingo::SymbolicLiteralSpan(current_assumptions));
        for(auto &model: solve_handle){
            sat = true;
            break;
        }

        if(!sat) 
            return DEAD_END;
        
        //TODO[asp] UGLY and potentially dangerous! Consider to change it in the future.
        heuristic->compute_heuristic_public(ancestor_state);
    }

    class AspHeuristicFeature: public plugins::TypedFeature<Evaluator, ASPHeuristic> {
    public:
        AspHeuristicFeature() : TypedFeature("asp") {
        document_title("Asp-based axiom solving feature");
        
        add_option<shared_ptr<Heuristic>>("heuristic", "base heuristic");
        add_option<string>("lp_file", "the file that clingo will use to solve axioms");
        add_heuristic_options_to_feature(*this, "asp");
        
        //TODO[asp] check for these support and properties!
        document_language_support("action costs", "supported");
        document_language_support("conditional effects", "supported");
        document_language_support("axioms", "supported");

        document_property("admissible", "yes");
        document_property("consistent", "no");
        document_property("safe", "yes");
        document_property("preferred operators", "no");
    }

     virtual shared_ptr<ASPHeuristic> create_component(
        const plugins::Options &opts) const override {
        return plugins::make_shared_from_arg_tuples<ASPHeuristic>(
            opts.get<shared_ptr<Heuristic>>("heuristic"),
            opts.get<string>("lp_file"),
            get_heuristic_arguments_from_options(opts));
    }
};

static plugins::FeaturePlugin<AspHeuristicFeature> _plugin;
}
