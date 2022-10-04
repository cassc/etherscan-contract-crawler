// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DYSToken is ERC20 {
    constructor(address beneficiary, uint totalSupply_) ERC20("DYSEUM Token", "DYS") {
        _mint(beneficiary, totalSupply_ * 10 ** decimals());
    }
}