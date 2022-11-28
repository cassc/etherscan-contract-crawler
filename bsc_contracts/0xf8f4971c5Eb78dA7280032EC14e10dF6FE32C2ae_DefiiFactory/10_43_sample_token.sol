// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleToken is ERC20 {
    constructor(address owner, uint256 initialSupply) ERC20("SampleToken", "ST") {
        _mint(owner, initialSupply);
    }
}