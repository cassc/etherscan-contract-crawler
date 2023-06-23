// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KIDGEN is ERC20 {
    constructor(uint256 initialSupply) ERC20("KIDGEN", "KIDGEN") {
        _mint(msg.sender, initialSupply);
    }
}