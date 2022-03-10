# Solwaifu

**Solwaifu is the most optimised ERC20 contract in existance. Written in pure bytecode.**

These contracts are not audited and should be used with the utmost care. Please make sure to understand the bytecode before you use it. If using solmate is like holding a gun to your foot then using solwaifu is like playing hopscotch in a minefield while specop snipers are taking potshots at you.

![Screenshot 2022-03-10 at 20 37 17](https://user-images.githubusercontent.com/37438950/157750303-8aeb63c4-4b1e-46c8-a540-664c4c9b2491.png)

# Installation

```
forge install outdoteth/solwaifu
```

# Usage

Because the ERC20 contract is written in pure bytecode it has to be deployed as a standalone:

```solidity
import { ERC20Deployer } from "solwaifu/ERC20Deployer.sol";

contract MyContract is ERC20Deployer {
    address tokenAddress;

    constructor() {
        uint256 decimals = 18;
        uint256 totalSupply = 100e18;
        address recipient = msg.sender;
        
        // Deploys the token at tokenAddress and 
        // sends the totalSupply to recipient
        tokenAddress = ERC20Deployer.deploy(
            "Buttcoin",
            "BUTT",
            decimals,
            totalSupply,
            recipient
        );
    }
}
```

# Benchmarks

![Screenshot 2022-03-10 at 20 41 11](https://user-images.githubusercontent.com/37438950/157750840-281e4a99-6f1b-458f-a024-2077f6f92293.png)

These benchmarks are obtained by running:

```
forge test --force -vvv --match-contract Benchmark
```

# Contributing

The goal is to get this implementation to the theoretical limit of gas optimisation for the ERC20 spec. The only rule is that it must adhere to the spec as defined in EIP-20. Everything else is fair game; Storage layout changes, memory layout changes, stack manipulations etc.

There are a few places where quite a lot optimisations can still be done. Mainly the `transferFrom` and `approve` functions.

Be careful when making changes. All of the JUMPI and JUMP input dests need to be updated with each change. It's a good idea to write the function your working on in evm.codes playground first and then port it over once you are sure it works. Remix is also a great resource.

To run tests:

```
forge test -vvvv --force
```
