# Relayer Gasless Contract for SimpleStorage Contract with Truffle Test


### Installing dependencies:-
```
yarn
```

### Running commands:-

```
//Start Ganache_cli for blockchain instance
yarn global add ganache-cli

//start ganache-cli
npx ganache-cli

// To compile the smart contract
yarn compile

// To deploy the smart contrct on polygon blockchain
yarn deploy

// To test the smart contract file
yarn test
```


## Understanding the GaslessRelayer Contract
The GaslessRelayer contract enables gasless transactions by relaying transactions on behalf of users. Here’s a brief overview of the key components:

* ```addToWhitelist(address _addressForWl):``` This function allows the contract owner to add an address to the whitelist, granting it permission to use the relayer.
* ```setGasPrice(uint256 newGasPrice):``` Allows the contract owner to set a new gas price threshold that users must meet to use the relayer.
* ```getNonce(address user):``` Returns the nonce for a given user’s address.
* ``` relay(...):``` The main function for relaying transactions. It verifies the signature, checks the nonce, and relays the transaction to the target contract.
* ```getMsgHash(...):``` Calculates the message hash for a given target, data, and nonce.
* ```getDataHash(...):``` Calculates the data hash for a given data input.
* ```recoverSigner(...):``` Recovers the signer’s address from a given message hash and signature.
* ```relayWithGasPrice(...):``` A helper function that relays a transaction while ensuring the gas price is above the specified threshold.

## Testing the GaslessRelayer Contract
* The provided test script (test/GaslessRelayer.js) demonstrates how to interact with the GaslessRelayer contract and perform various operations, including:
* Deploying the GaslessRelayer and SimpleStorage contracts.
* Adding a signer address to the whitelist.
* Calculating data and message hashes.
* Signing a message.
* Relaying a transaction using the GaslessRelayer.

```
// Test the GaslessRelayer with command:
yarn test .\test\GaslessRelayer.test.js
```


* Gasless transactions require a relayer to pay for the gas. Make sure you have a reliable and trusted relayer before using this contract on a mainnet or production environment.
Always test your contracts thoroughly on a local network or testnet before deploying to the mainnet.
Security is crucial in smart contract development. Audit your contracts for potential vulnerabilities and follow best practices.