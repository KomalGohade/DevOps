az group create --name vscode --location 'Central US'
az deployment group create --resource-group vscode --template-file 01-create-vm.json
