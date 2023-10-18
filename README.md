# Puppet Environment Syncer

This script is designed to synchronize the Puppet environments in Satellite with the desired state defined in a YAML file or a list provided through command-line arguments. It ensures that your Puppet environments in Satellite match exactly what's defined in your project specifications, adding missing environments and removing the redundant ones.

**Note:** The script protects the 'production' environment from being removed.

## Requirements

- Ruby (tested on default RHEL8)
- The 'hammer' CLI tool installed and accessible at `/usr/bin/hammer`

## Usage

This script can be used in two ways: by specifying a YAML file containing the desired environments or by listing the environments directly in a comma-separated list. Below are the command-line arguments that can be used with this script:

- `-f FILE`, `--file FILE`: Path to a YAML file containing the desired environments. This file should be in the format:
    ```yaml
    ---
    - environment_name_1
    - environment_name_2
    ```

- `-e x,y,z`, `--environments x,y,z`: A direct list of environments to be synchronized, separated by commas.

**Example usage:**

```bash
# Using a file
./sync_puppet_environments.rb --file /path/to/environments.yaml

# Using a direct list
./sync_puppet_environments.rb --environments dev,test,prod
```

## Running Tests

### Prerequisites

- Make sure you have `bundler` installed. If not, you can install it using:
    ```sh
    gem install bundler
    ```

- Next, install all the project dependencies by running:
    ```sh
    bundle install
    ```

### Executing Tests and Code Analysis

1. In your terminal, navigate to the project's root directory.
2. Run the following command to execute all tests and perform code analysis:
    ```sh
    bundle exec rake
    ```
This command will run all the Rspec tests in the project (following the pattern `spec/**/*_spec.rb`) and perform a RuboCop analysis for ensuring code quality.

