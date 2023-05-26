// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract STEWIE is ERC20, Ownable {
    constructor() ERC20("STEWIE", "STEW") {
        _mint(msg.sender, 69420420420 * 10 ** decimals());
    }
}