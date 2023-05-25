// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract NoSellButtonCom is ERC20, Ownable {
    constructor() ERC20("NoSellButton.com", "HONOR") {
        _mint(msg.sender, 999999999999 * 10 ** decimals());
    }
}