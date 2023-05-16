// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Website: https://discord-coin.netlify.app/
// Telegram: https://t.me/+NauRO2kOhOc3NzRh
// Twitter: https://twitter.com/CoinDiscord8391

pragma solidity ^0.8.0;

contract Discord is ERC20 {
    constructor(uint256 _totalSupply) ERC20("DISCORD", "DISCORD") {
        _mint(msg.sender, _totalSupply);
    }
}