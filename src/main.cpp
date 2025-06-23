#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "helpers.hpp"

namespace espaceCodes
{
std::string reset = "\033[0m";
std::string green = "\033[32m";
std::string bold_green = "\033[1;32m";
std::string red = "\033[31m";
std::string bold_red = "\033[1;31m";
} // namespace espaceCodes

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

const std::vector<std::string> pacman_packages = get_pacman_packages();

struct CommandResult
{
  bool success;
  std::string output;
};

CommandResult executeCommand(const std::string &command)
{
  std::array<char, 4096> buffer;
  CommandResult result;

  std::string fullCommand = command + " 2>&1";

  FILE *fp = popen(fullCommand.c_str(), "r");
  if (!fp)
  {
    result.success = false;
    result.output = "Failed to execute command: " + fullCommand;
    return result;
  }

  while (fgets(buffer.data(), buffer.size(), fp) != nullptr)
  {
    result.output += buffer.data();
  }

  result.success = pclose(fp) == 0;

  return result;
}

void installPacmanPackage(const std::string &package)
{
  static const std::string successText = espaceCodes::bold_green + "success" + espaceCodes::reset;
  static const std::string failureText = espaceCodes::bold_red + "failure" + espaceCodes::reset;

  std::string command = "sudo pacman -S --noconfirm " + package;
  CommandResult result = executeCommand(command);

  if (config::verbose)
  {
    std::cout << "Installing " << package << "...\n";
    std::cout << remove_consecutive_newlines(result.output);
  }
  else if (!result.success)
  {
    std::cout << "Failed to install " << package << ": " << result.output;
  }

  std::cout << package << ": " << "[" << (result.success ? successText : failureText) << "]\n";

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
  for (const auto &packageName : pacman_packages)
  {
    installPacmanPackage(packageName);
  }
}