# Istio Policy Generator

Istio Policy Generator is a Bash script tool designed to streamline the process of generating and applying Istio VirtualService policies in a Kubernetes cluster. The tool reads a YAML configuration file specifying the services and their corresponding paths, and generates the appropriate VirtualService policies.

## Features

- **Automated Policy Generation**: Generates Istio VirtualService policies from a YAML configuration file.
- **Path-Based Routing**: Supports routing specific paths or all traffic for a given service.
- **Modular Templates**: Uses separate templates for different policy configurations for easy customization.
- **Kubernetes Integration**: Applies the generated policies directly to a Kubernetes cluster.

## Usage

1. **Clone the Repository**
   ```sh
   git clone https://github.com/yourusername/istio-policy-generator.git
   cd istio-policy-generator
   ```

2. **Set Up Templates**
   Ensure the following templates are present in the `templates` directory:
   - `template_redirect_all.yaml`
   - `template_redirect_paths.yaml`
   - `template_route_item.yaml`

3. **Configure Services**
   Edit the `config.yaml` file to specify your services and paths. Example:
   ```yaml
   service1:
     paths:
       - /api/v1
       - /api/v2
   service2: {}
   service3:
     paths:
       - /user/login
       - /user/register
   service4: {}
   ```

4. **Generate Policies**
   Run the script to generate the Istio policies:
   ```sh
   ./generate_istio_policies.sh
   ```

5. **Apply Policies to Kubernetes**
   Apply the generated policies to your Kubernetes cluster:
   ```sh
   ./apply_istio_policies.sh
   ```

## Requirements

- `gojq`: Install using `go install github.com/itchyny/gojq/cmd/gojq@latest`
- `kubectl`: Install according to your OS [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## License

This project is licensed under the MIT License.
