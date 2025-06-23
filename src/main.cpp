#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "helpers.hpp"

namespace escape_codes
{
const std::string reset = "\033[0m";
const std::string green = "\033[32m";
const std::string bold_green = "\033[1;32m";
const std::string red = "\033[31m";
const std::string bold_red = "\033[1;31m";
} // namespace escape_codes

namespace config
{
bool verbose;
}

std::vector<std::string> get_pacman_packages()
{
  // use cmake to include `package` in the build dir, I am too lazy right now :)
  const std::string package_file_path = std::filesystem::path(std::getenv("HOME")) / "repos/arch-install/packages";
  std::ifstream packages_file(package_file_path);
  if (!packages_file.is_open())
  {
    throw std::runtime_error("Unable to open packages file");
  }

  std::vector<std::string> lines;
  std::string line;

  while (std::getline(packages_file, line))
  {
    if (line[0] == '#')
    {
      continue;
    }
    lines.push_back(line);
  }

  return lines;
};

struct CommandResult
{
  bool success;
  std::string output;
};

CommandResult execute_command(const std::string &command)
{
  std::array<char, 4096> buffer;
  CommandResult result;

  std::string full_command = command + " 2>&1";

  FILE *fp = popen(full_command.c_str(), "r");
  if (!fp)
  {
    result.success = false;
    result.output = "Failed to execute command: " + full_command;
    return result;
  }

  while (fgets(buffer.data(), buffer.size(), fp) != nullptr)
  {
    result.output += buffer.data();
  }

  result.success = pclose(fp) == 0;

  return result;
}

void install_pacman_package(const std::string &package)
{
  static const std::string success_text = escape_codes::bold_green + "success" + escape_codes::reset;
  static const std::string failure_text = escape_codes::bold_red + "failure" + escape_codes::reset;

  std::string command = "sudo pacman -S --noconfirm " + package;
  CommandResult result = execute_command(command);

  if (config::verbose)
  {
    std::cout << "Installing " << package << "...\n";
    std::cout << remove_consecutive_newlines(result.output);
  }
  else if (!result.success)
  {
    std::cout << "Failed to install " << package << ": " << result.output;
  }

  std::cout << package << ": " << "[" << (result.success ? success_text : failure_text) << "]\n";

  if (config::verbose)
  {
    std::cout << "\n";
  }
}

int main(int argc, char *argv[])
{
  std::cout << "~~~Installing Arch Linux~~~\n\n";

  for (int i = 1; i < argc; ++i)
  {
    const std::string arg = argv[i];
    if (arg == "--verbose" || arg == "-v")
    {
      config::verbose = true;
    }
  }

  std::cout << "Installing AUR packages\n";
  for (const auto &packageName : get_pacman_packages())
  {
    install_pacman_package(packageName);
  }
}