#ifndef HEURISTICS_ASP_HEURISTIC_H
#define HEURISTICS_ASP_HEURISTIC_H

#include "../heuristic.h"
#include <string>
#include <memory> // for std::shared_ptr
#include <clingo.hh>

//TODO[asp] change location (and maybe transform into a macro?)
namespace {
    std::string ASP_TYPES_FILENAME = "instance_types.lp";
    std::string ASP_STATIC_FACTS_FILENAME = "instance_static_facts.lp";
}

namespace asp_heuristic{
    class ASPHeuristic: public Heuristic {
            std::string lp_file;
            std::shared_ptr<Heuristic> heuristic;

            std::string static_facts;
            std::vector<std::vector<std::string>> fact_by_value;

            std::hash<std::string> hasher;
            std::unordered_map<size_t, bool> cache_eval; 


            //void evaluate(size_t hashed_key, std::string dynamic_facts);
        protected:
            virtual int compute_heuristic(const State &ancestor_state) override;
        public:
            explicit ASPHeuristic(
                const std::shared_ptr<Heuristic> &heuristic,
                const std::string &lp_file, 
                const std::shared_ptr<AbstractTask> &transform, 
                bool cache_estimates,
                const std::string &description, 
                utils::Verbosity verbosity);
    };     
}

#endif //HEURISTICS_ASP_HEURISTIC_H
