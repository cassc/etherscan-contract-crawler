// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Website: https://spacex-coin.netlify.app/
// Telegram: https://t.me/+yTsSKfWFL6wzMzFh
// Twitter: https://twitter.com/SpaceXcoin69

pragma solidity ^0.8.0;

contract SPACEX is ERC20 {
    constructor(uint256 _totalSupply) ERC20("SPACEX", "SPACEX") {
        _mint(msg.sender, _totalSupply);
    }
}