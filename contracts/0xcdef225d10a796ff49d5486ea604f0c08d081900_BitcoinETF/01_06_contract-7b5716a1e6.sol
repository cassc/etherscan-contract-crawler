// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract BitcoinETF is ERC20, Ownable {
    constructor() ERC20("BitcoinETF", "BTCETF") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}