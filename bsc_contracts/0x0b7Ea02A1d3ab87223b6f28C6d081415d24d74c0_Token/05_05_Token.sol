//SPDX-License-Identifier: Unlicense

//pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    uint constant _initial_supply = 420690000000000 * (10**18);
    constructor() ERC20("Planet Pluto", "PLUTO") {
        _mint(msg.sender, _initial_supply);
    }
}