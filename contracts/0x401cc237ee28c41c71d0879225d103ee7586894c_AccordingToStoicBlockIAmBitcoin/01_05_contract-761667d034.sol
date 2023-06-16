// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract AccordingToStoicBlockIAmBitcoin is ERC20 {
    error AccordingToStoicBlockIAmBitcoin__TooMuch();
    uint256 public constant TOTAL_SUPPLY_CAP = 21_000_000e18; // 21 million
    constructor() ERC20("AccordingToStoicBlockIAmBitcoin", "SBTC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
        if (totalSupply() > TOTAL_SUPPLY_CAP){
            revert AccordingToStoicBlockIAmBitcoin__TooMuch();
        }
    }
}