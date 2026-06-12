#include "asp_heuristic.h"

#include "../plugins/plugin.h"
#include "../task_utils/task_properties.h"
#include "../utils/asp_fact_converter.h"
#include "../task_proxy.h"
#include "../utils/logging.h"

using namespace std;

/*TODO[asp] There is some cleaning to do. But for now it's acceptable.
*/

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
                    static_facts += utils::read_file(ASP_TYPES_FILENAME);
                    static_facts += utils::read_file(ASP_STATIC_FACTS_FILENAME);
                    static_facts += utils::read_file(lp_file); 
                    
                    TaskProxy task_proxy(*transform);
                    VariablesProxy vars = task_proxy.get_variables();

                    fact_by_value.resize(vars.size());

                    for (VariableProxy var : vars) {
                        int id = var.get_id();
                        int dom = var.get_domain_size();
                        fact_by_value[id].resize(dom);
    
                        for (int v = 0; v < dom; ++v) {
                            fact_by_value[id][v] = utils::atom_to_asp(var.get_fact(v).get_name());
                        }
                    }
                    //log<<"Created heuristic!"<<endl;
                }
    int ASPHeuristic::compute_heuristic(const State &ancestor_state){
        Clingo::Control ctl{};  

        string ckey = "";
        string dynamic_facts = "";

        ancestor_state.unpack();
        const std::vector<int>& state_values = ancestor_state.get_unpacked_values(); 

        for (size_t var_id = 0; var_id < fact_by_value.size(); ++var_id) {

            const string &asp_fact = fact_by_value[var_id][state_values[var_id]];
    
            if (!asp_fact.empty()) {
                dynamic_facts += asp_fact + ". ";
                ckey += asp_fact + ';';
            }
        }

        /*
        VariablesProxy vars = ancestor_state.get_task().get_variables();
        for(VariableProxy var: vars){

            FactProxy fact = ancestor_state[var.get_id()];
            string asp_fact = utils::atom_to_asp(fact.get_name());

            if (!asp_fact.empty()) {
                dynamic_facts += asp_fact + ". ";
                ckey += asp_fact + ';';
            }
        }
        */

        size_t hashed_ckey = hasher(ckey);
        auto it = cache_eval.find(hashed_ckey);

        // 2. Check if the iterator is valid
        if (it != cache_eval.end()){
            if(cache_eval[hashed_ckey])
                return heuristic->compute_heuristic_public(ancestor_state);

            return DEAD_END;
        }

        string prog = dynamic_facts + "\n" + static_facts;
        ctl.add("base", {}, prog.c_str());
    
        ctl.ground({{"base", {}}});
    
        bool sat = false;
        auto solve_handle = ctl.solve();
        for(auto &model : solve_handle){
            sat = true; 
            cache_eval[hashed_ckey] = true;
            break;
        }
    
        if(!sat){
            cache_eval[hashed_ckey] = false;
            return DEAD_END;
        }    
        return heuristic->compute_heuristic_public(ancestor_state);
    }

    class AspHeuristicFeature: public plugins::TypedFeature<Evaluator, ASPHeuristic> {
    public:
        AspHeuristicFeature() : TypedFeature("asp") {
        document_title("Asp-based axiom solving feature");
        
        add_option<shared_ptr<Evaluator>>("heuristic", "base heuristic");
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
            auto base_eval = opts.get<shared_ptr<Evaluator>>("heuristic");
            auto base_heur = dynamic_pointer_cast<Heuristic>(base_eval);
            //TODO[asp] add check on casting!
        return plugins::make_shared_from_arg_tuples<ASPHeuristic>(
            base_heur,
            opts.get<string>("lp_file"),
            get_heuristic_arguments_from_options(opts));
    }
};

static plugins::FeaturePlugin<AspHeuristicFeature> _plugin;
}
