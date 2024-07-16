# Istio Policy Generator

Istio Policy Generator is a Bash script tool designed to streamline the process of generating and applying Istio VirtualService policies in a Kubernetes cluster. The tool reads a YAML configuration file specifying the services and their corresponding paths, and generates the appropriate VirtualService policies.

## Features

- **Automated Policy Generation**: Generates Istio VirtualService policies from a YAML configuration file.
- **Path-Based Routing**: Supports routing specific paths or all traffic for a given service.
- **Modular Templates**: Uses separate templates for different policy configurations for easy customization.
- **Environment Variables**: Allows setting default values for namespace, host, port, prefix, and labels via environment variables.
- **Kubernetes Integration**: Applies the generated policies directly to a Kubernetes cluster.

## Usage

1. **Clone the Repository**
   ```sh
   git clone https://github.com/fabianomonteiro/istio-policy-generator.git
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
     host: host2
     port: 2222
     namespace: other-ns
     prefix: /other/prefix
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

4. **Set Environment Variables**
   Define the environment variables with default values. These values will be used if not specified in the `config.yaml`:
   ```sh
   export NAMESPACE="default"
   export NEW_HOST="new-destination"
   export PORT="80"
   export LABEL_KEY="app"
   export LABEL_VALUE="default"
   export PREFIX="/"
   ```

5. **Generate Policies**
   Run the script to generate the Istio policies:
   ```sh
   ./generate_istio_policies.sh
   ```

6. **Apply Policies to Kubernetes**
   Apply the generated policies to your Kubernetes cluster:
   ```sh
   ./apply_istio_policies.sh
   ```

## Template Files

### `template_redirect_all.yaml`
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{serviceName}}
  namespace: {{namespace}}
  labels:
    {{labelKey}}: {{labelValue}}
spec:
  hosts:
  - {{host}}
  http:
  - route:
    - destination:
        host: {{newHost}}
        port:
          number: {{port}}
```

### `template_redirect_paths.yaml`
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: {{serviceName}}
  namespace: {{namespace}}
  labels:
    {{labelKey}}: {{labelValue}}
spec:
  hosts:
  - {{host}}
  http: {{http_routes}}
```

### `template_route_item.yaml`
```yaml
  - match:
    - uri:
        prefix: {{prefix}}
    route:
    - destination:
        host: {{newHost}}
        port:
          number: {{port}}
```

## Requirements

- `gojq`: Install using `go install github.com/itchyny/gojq/cmd/gojq@latest`
- `kubectl`: Install according to your OS [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## License

This project is licensed under the MIT License.

### Estrutura do Projeto:
```
istio-policy-generator/
├── templates/
│   ├── template_redirect_all.yaml
│   ├── template_redirect_paths.yaml
│   ├── template_route_item.yaml
├── config.yaml
├── generate_istio_policies.sh
├── apply_istio_policies.sh
└── README.md
```