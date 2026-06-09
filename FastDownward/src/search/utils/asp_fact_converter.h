#ifndef ASP_FACT_CONVERTER_H
#define ASP_FACT_CONVERTER_H

#include <string>
#include <cctype>

namespace utils{
    std::string atom_to_asp(const std::string &factname);
}

#endif