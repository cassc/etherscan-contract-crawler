// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract DOGEZILLA is ERC20 {
    constructor(uint256 initialSupply) ERC20("DOGEZILLA", "DZILLA") {
        _mint(msg.sender, initialSupply);
    }
    function decimals() override public view returns (uint8) {
        return 2;
    }
}