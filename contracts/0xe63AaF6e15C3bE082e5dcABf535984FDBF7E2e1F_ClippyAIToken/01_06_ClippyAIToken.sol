//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * Website: https://clippy.wtf
 * Telegram: https://t.me/+3xcRwlEQ8Q1iMTlk
 * Are you ready to witness the resurrection of the legendary AI assistant from the Windows 98 era? Clippy is back, and this time it's not to help you write a letter or format a spreadsheet. ClippyAI is here to revolutionize the world of decentralized finance and pay homage to the iconic virtual assistant that once graced our screens.
 * Get ready to dive into the degenerate world of ClippyAI, where innovation meets nostalgia. We've taken the concept of memecoins to a whole new level, combining it with the power of artificial intelligence. Say hello to $CLIPPY, the token that will make waves in the crypto community and beyond.
 */
contract ClippyAIToken is Ownable, ERC20 {
    constructor(uint256 _totalSupply) ERC20("ClippyAI", "CLIPPY") {
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}