//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Yoshi is ERC20 {
    uint constant _initial_supply = 420690000000000 * (10**18);
    constructor() ERC20("Yoshi", "YOSHI") {
        _mint(msg.sender, _initial_supply);
    }
}