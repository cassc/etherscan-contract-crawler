// SPDX-License-Identifier: MIT

// Telegram: t.me/ShrekERC
// Twitter : twitter.com/Shrek_ERC

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Shrek is ERC20, Ownable {
    constructor() ERC20("Shrek", "SHREK") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}