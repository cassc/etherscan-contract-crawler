// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NotX is ERC20 {
    constructor(uint256 initialSupply) ERC20("NotX", "NotX") {
        uint256 tokenSupply = initialSupply * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}