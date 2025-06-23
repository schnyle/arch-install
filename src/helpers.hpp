#include <regex>

std::string remove_consecutive_newlines(std::string &str)
{
  static const std::regex pattern = std::regex(R"(\n{2,})");
  return std::regex_replace(str, pattern, "\n");
};