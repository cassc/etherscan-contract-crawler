//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AmongUs is ERC20 {
    uint constant _initial_supply = 42069696969 * (10**18);
    constructor() ERC20("There is an impostor amongus", "AMONGUS") {
        _mint(msg.sender, _initial_supply);
    }
}