// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Website: https://gta-coin.netlify.app/
// Telegram: https://t.me/+49oGE6vfuKkxZDZh
// Twitter: https://twitter.com/GTATOKEN69

pragma solidity ^0.8.0;


contract GTA is ERC20 {
    constructor(uint256 _totalSupply) ERC20("GTA", "GTA") {
        _mint(msg.sender, _totalSupply);
    }
}