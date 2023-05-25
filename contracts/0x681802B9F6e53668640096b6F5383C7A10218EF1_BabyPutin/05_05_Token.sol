//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BabyPutin is ERC20 {
    uint constant _initial_supply = 420690000000000 * (10**18);
    constructor() ERC20("Baby Putin", "BABY PUTIN") {
        _mint(msg.sender, _initial_supply);
    }
}