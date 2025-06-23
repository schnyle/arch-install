#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace espaceCodes
{
std::string reset = "\033[0m";
std::string green = "\033[32m";
std::string bold_green = "\033[1;32m";
std::string red = "\033[31m";
std::string bold_red = "\033[1;31m";
} // namespace espaceCodes

std::vector<std::string> get_pacman_packages()
{
  // use cmake to include `package` in the build dir, I am too lazy right now :)
  const std::string package_file_path = std::filesystem::path(std::getenv("HOME")) / "repos/arch-install/packages";
  std::cout << "package_file_path: " << package_file_path << "\n";
  std::ifstream packages_file(package_file_path);
  if (!packages_file.is_open())
  {
    throw std::runtime_error("Unable to open packages file");
  }

  std::vector<std::string> lines;
  std::string line;

  while (std::getline(packages_file, line))
  {
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
  std::cout << "Installing " << package << "... ";

  CommandResult result = executeCommand(command);

  std::string status = result.success ? successText : failureText;
  std::cout << "[" << status << "]\n";
  std::cout << result.output << "\n";

  if (!result.success)
  {
    std::cout << "Error installing package: " << package << ":\n" << result.output;
  }
}

int main()
{
  std::cout << "~~~Installing Arch Linux~~~\n";

  for (const auto &packageName : pacman_packages)
  {
    installPacmanPackage(packageName);
  }
}