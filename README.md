# Copy-Investing Smart Contracts

## Key components
- `vault-factory` -> Create the factory contract of the vault.
- `vault` -> Inherits from the standard ERC20 contract, uses EIP1967 beacon proxy mode to store universal logic contracts.
- `guardian` -> The entry contract for operating the vault. All operations on the vault can only be performed from here, also adopting EIP1967 beacon proxy mode to store common operational logic, including deposit, redemption, follow, extensionCall, and so on.
- `price-feed` -> The price feed contract, using the Chainlink oracle.
- `value-evaluator` -> A tool that uses the prices from the price feed for price calculations, such as calculating the ratios between various assets, etc.
- `extensions` -> External extensions currently only have external interaction (`integrationManager`), and temporarily only implement 0x version v4.
- `external-interface` -> The interface of external interaction contracts, such as 0x exchange, Chainlink, WETH, etc.
- `utils` -> Various tools.

### Developed with Fundry

Please refer to `script/deploy/sol` for contract deployment.
