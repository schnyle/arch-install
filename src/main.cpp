#include <array>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

namespace espaceCodes
{
std::string reset = "\033[0m";
std::string green = "\033[32m";
std::string boldGreen = "\033[1;32m";
std::string red = "\033[31m";
std::string boldRed = "\033[1;31m";
} // namespace espaceCodes

std::vector<std::string> pacmanPackages({
    "vim",
    "fjaskd",
    "nano",
    // "alacritty",
    // "arandr",
    // "cmake",
    // "git",
    // "base-devel",
    // "i3",
    // "lib32-nvidia-utils",
    // "nano",
    // "networkmanager",
    // "nvidia",
    // "nvidia-utils",
    // "nvidia-settings",
    // "openssh",
    // "pavucontrol",
    // "picom",
    // "pulseaudio",
    // "steam",
    // "tmux",
    // "vim",
    // "xclip",
    // "xorg-server",
    // "xorg-init",
    // "xorg-apps",
});

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
  static const std::string successText = espaceCodes::boldGreen + "success" + espaceCodes::reset;
  static const std::string failureText = espaceCodes::boldRed + "failure" + espaceCodes::reset;

  std::string command = "sudo pacman -S --noconfirm " + package;
  std::cout << "Installing " << package << "... ";

  CommandResult result = executeCommand(command);

  std::string status = result.success ? successText : failureText;
  std::cout << "[" << status << "]\n";

  if (!result.success)
  {
    std::cout << "Error installing package: " << package << ":\n" << result.output;
  }
}

int main()
{
  std::cout << "~~~Installing Arch Linux~~~\n";

  for (const auto &packageName : pacmanPackages)
  {
    installPacmanPackage(packageName);
  }
}