// SPDX-License-Identifier: MIT

// contracts/Olameno.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Olameno is ERC20 {
    constructor(uint256 initialSupply) ERC20("Olameno LA", "OL2") {
        _mint(0x46D2D182ba637bC1E725A48F4bB2c2275AC0190f, initialSupply * 10 ** decimals());
    }
}