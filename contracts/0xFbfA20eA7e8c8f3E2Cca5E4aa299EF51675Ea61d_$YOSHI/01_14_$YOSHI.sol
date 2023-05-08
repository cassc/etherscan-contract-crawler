// WEBSITE https://www.yoshi-erc20.com/

// TELEGRAM https://t.me/YOSHI_PORTAL

// TWITTER https://twitter.com/yoshi_erc20

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract $YOSHI is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("$YOSHI", "$YOSHI") ERC20Permit("$YOSHI") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
}