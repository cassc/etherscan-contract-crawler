// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HOCUSPOCUS is ERC20 {
    constructor(uint256 initialSupply) ERC20("HOCUS", "POCUS") {
        _mint(msg.sender, initialSupply);
    }
}

// (3,3) Together