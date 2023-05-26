// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Paipai is ERC20, Ownable {
    constructor() ERC20("Paipai", "PAIPAI") {
        _mint(msg.sender, 100000000069420 * 10 ** decimals());
    }
}