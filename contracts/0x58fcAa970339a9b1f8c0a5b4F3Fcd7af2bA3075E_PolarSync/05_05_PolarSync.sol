// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PolarSync is ERC20 {
    uint constant _initial_supply = 1000000000 * (10**18);
    constructor() ERC20("PolarSync", "POLAR") {
        _mint(msg.sender, _initial_supply);
    }
}