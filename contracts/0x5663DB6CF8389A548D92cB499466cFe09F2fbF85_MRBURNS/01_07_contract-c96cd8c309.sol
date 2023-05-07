// TELEGRAM https://t.me/MR_BURNS_ERC20

// TWITTER https://twitter.com/mr_burns_erc20

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract MRBURNS is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("MR BURNS", "$BURNS") {
        _mint(msg.sender, 10000000000000000 * 10 ** decimals());
    }
}