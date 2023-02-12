// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Darik is ERC20, Ownable {
    constructor() ERC20("Darik Coin", "DARIK") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}