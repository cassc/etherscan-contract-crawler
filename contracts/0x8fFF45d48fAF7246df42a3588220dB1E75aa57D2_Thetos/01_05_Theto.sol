// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Thetos


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Thetos is ERC20 {
    constructor(uint256 initialSupply) ERC20("THETOS", "THT") {
        _mint(msg.sender, initialSupply);
    }
}