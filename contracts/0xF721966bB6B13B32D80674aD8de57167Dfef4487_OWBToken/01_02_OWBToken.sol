// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/src/tokens/ERC20.sol";

contract OWBToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initSupply
    ) ERC20(name, symbol, 18) {
        _mint(msg.sender, initSupply * 10 ** decimals);
    }
}