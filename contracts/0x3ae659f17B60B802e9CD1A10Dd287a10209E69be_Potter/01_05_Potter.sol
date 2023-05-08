// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Twitter: https://twitter.com/HarryPottter420
// Telegram: https://t.me/+6NpE-0CVjx1kNTFh
// Website: https://potter-coin.netlify.app

pragma solidity ^0.8.0;


contract Potter is ERC20 {
    constructor(uint256 _totalSupply) ERC20("Potter", "POTTER") {
        _mint(msg.sender, _totalSupply);
    }
}