// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MsPepe is ERC20, Ownable {
    constructor() ERC20("MsPepe", "MSPEPE") {
        _mint(msg.sender, 531053105310531053105 * 10 ** decimals());
    }
}