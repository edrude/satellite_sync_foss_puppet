# Puppet Environment Syncer

This script is designed to synchronize the Puppet environments in Satellite with the desired state defined in a YAML file or a list provided through command-line arguments. It ensures that your Puppet environments in Satellite match exactly what's defined in your project specifications, adding missing environments and removing the redundant ones.

**Note:** The script protects the 'production' environment from being removed.

## Requirements

- Ruby (tested on default RHEL8)
- The 'hammer' CLI tool installed and accessible at `/usr/bin/hammer`

## Usage

### Executing Tests and Code Analysis

1. In your terminal, navigate to the project's root directory.
2. Run the following command to execute all tests and perform code analysis:
    ```sh
    bundle exec rake
    ```
This command will run all the Rspec tests in the project (following the pattern `spec/**/*_spec.rb`) and perform a RuboCop analysis for ensuring code quality.

