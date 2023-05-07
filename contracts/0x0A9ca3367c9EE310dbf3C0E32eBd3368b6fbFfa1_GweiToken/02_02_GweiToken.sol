// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solady/tokens/ERC20.sol";

contract GweiToken is ERC20 {
    uint private constant _numTokens = 1_000_000_000_000_000;

    constructor() {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function name() public view virtual override returns (string memory) {
        return "Gas DAO";
    }

    function symbol() public view virtual override returns (string memory) {
        return "GWEI";
    }

    function gasDao() public pure returns (string memory) {
        return
            "Gas DAO is a DAO that is focused on reducing the gas fees on the Ethereum network. We are a community of developers, designers, and crypto enthusiasts that are working together to make Ethereum more accessible to everyone.";
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}