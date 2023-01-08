// contracts/EinpunkUSD.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EinpunkUSD is ERC20 {
    constructor(uint256 initialSupply) ERC20("EinpunkUSD", "Einpunk") {
        _mint(msg.sender, initialSupply);
    }
}