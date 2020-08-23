# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Package Information

Truffle v5.1.41 (core: 5.1.41)
Solidity - ^0.5.15 (solc-js)
Node v12.18.2
Web3.js v1.2.1

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

```npm install```
```(optional) npm i rimraf``` 
```(optional) npm i webpack``` 

## Run

Launch Ganache:

`ganache-cli -m "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" -a 35 -l 9999999999`

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate --reset`
`npm run server`
`npm run dapp`

To view dapp:

`http://localhost:8000`


Dapp screen shot:

![img](img/dapp.png)



## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)
