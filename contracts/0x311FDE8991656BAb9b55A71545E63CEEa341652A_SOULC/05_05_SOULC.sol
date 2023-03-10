// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract SOULC is ERC20 {
    constructor(uint256 initialSupply, address a) ERC20("Soul Chat Coin", "SOULC") {
        // Will be used to for yield multiplier on Ultra Yield platform
        _mint(a, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}