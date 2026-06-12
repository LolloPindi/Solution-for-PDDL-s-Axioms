#include "asp_fact_converter.h"

#include <fstream>
#include <fstream>
#include <sstream>
#include <cctype>

namespace utils{

    std::string atom_to_asp(const std::string &factname) {
        const std::string pref = "Atom ";
        if (factname.rfind(pref, 0) != 0)
            return "";
        std::string body = factname.substr(pref.size());
        std::string out;
        out.reserve(body.size());
        for (char c : body)
            if (c != ' ')
                out += (c == '-') ? '_' : c;
        if (out.size() >= 2 && out.substr(out.size() - 2) == "()")
            out = out.substr(0, out.size() - 2);
        for (char &c : out)
            c = (char)::tolower((unsigned char)c);   // ASP: nomi minuscoli
        return out;
    }

    std::string read_file(const std::string &path) {
        std::ifstream f(path);
        if (!f)
            throw std::runtime_error("[clingo] Unable to read: " + path);
        std::stringstream ss;
        ss << f.rdbuf();
        return ss.str();
    }
}