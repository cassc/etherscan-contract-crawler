//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PEPERISEToken is ERC20 {
    uint constant _initial_supply = 920690000000000 * (10**18);
    constructor() ERC20("PepeRise", "PEPE RISE") {
        _mint(msg.sender, _initial_supply);
    }
}