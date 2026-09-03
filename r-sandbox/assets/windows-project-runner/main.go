package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	appName       = "R Sandbox"
	shellLauncher = "run-r-sandbox.sh"
)

var agent = ""

func main() {
	err := run()
	fmt.Println()
	if err != nil {
		fmt.Fprintln(os.Stderr, appName+" stopped:", err)
	} else {
		fmt.Println(appName, "opened successfully.")
	}
	fmt.Print("Press Enter to close this window...")
	_, _ = bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		os.Exit(1)
	}
}

func run() error {
	if agent != "codex" && agent != "claude" {
		return errors.New("the project runner has an invalid configured agent")
	}
	executable, err := os.Executable()
	if err != nil {
		return fmt.Errorf("locate project runner: %w", err)
	}
	codeDir := filepath.Dir(executable)
	launcher := filepath.Join(codeDir, shellLauncher)
	if info, err := os.Stat(launcher); err != nil || info.IsDir() {
		return fmt.Errorf("project launcher is unavailable: %s", launcher)
	}
	bash, err := findGitBash()
	if err != nil {
		return err
	}
	if err := addVSCodeToPath(); err != nil {
		return err
	}
	unixLauncher, err := cygpath(bash, launcher)
	if err != nil {
		return err
	}
	cmd := exec.Command(bash, unixLauncher, agent)
	cmd.Dir = filepath.Dir(codeDir)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("sandbox launcher failed: %w", err)
	}
	return nil
}

func findGitBash() (string, error) {
	candidates := []string{
		filepath.Join(os.Getenv("ProgramFiles"), "Git", "bin", "bash.exe"),
		filepath.Join(os.Getenv("ProgramFiles"), "Git", "usr", "bin", "bash.exe"),
		filepath.Join(os.Getenv("LocalAppData"), "Programs", "Git", "bin", "bash.exe"),
	}
	if path, err := exec.LookPath("bash.exe"); err == nil {
		candidates = append(candidates, path)
	}
	seen := map[string]bool{}
	for _, path := range candidates {
		key := strings.ToLower(path)
		if path == "" || seen[key] {
			continue
		}
		seen[key] = true
		if info, err := os.Stat(path); err == nil && !info.IsDir() && isGitBash(path) {
			return path, nil
		}
	}
	return "", errors.New("Git Bash is required; install Git for Windows from https://git-scm.com/download/win")
}

func isGitBash(path string) bool {
	output, err := exec.Command(path, "-lc", `printf '%s' "$(uname -s)"; command -v cygpath >/dev/null`).CombinedOutput()
	return err == nil && strings.HasPrefix(strings.ToUpper(strings.TrimSpace(string(output))), "MINGW")
}

func addVSCodeToPath() error {
	if _, err := exec.LookPath("code.cmd"); err == nil {
		return nil
	}
	candidates := []string{
		filepath.Join(os.Getenv("LocalAppData"), "Programs", "Microsoft VS Code", "bin"),
		filepath.Join(os.Getenv("ProgramFiles"), "Microsoft VS Code", "bin"),
	}
	for _, directory := range candidates {
		if _, err := os.Stat(filepath.Join(directory, "code.cmd")); err == nil {
			return os.Setenv("PATH", os.Getenv("PATH")+";"+directory)
		}
	}
	return errors.New("Visual Studio Code is required; install it from https://code.visualstudio.com/")
}

func cygpath(bash, path string) (string, error) {
	cmd := exec.Command(bash, "-lc", `cygpath -u "$1"`, "runner", path)
	var output bytes.Buffer
	cmd.Stdout = &output
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("convert the Windows project path for Git Bash: %w", err)
	}
	return strings.TrimSpace(output.String()), nil
}
