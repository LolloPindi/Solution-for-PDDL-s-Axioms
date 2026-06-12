#ifndef ASP_FACT_CONVERTER_H
#define ASP_FACT_CONVERTER_H

#include <string>

namespace utils{
    std::string atom_to_asp(const std::string &factname);
    std::string read_file(const std::string &path);
}

#endif