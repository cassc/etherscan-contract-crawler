// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Twitter: https://twitter.com/RickRoll420691
// Telegram: https://t.me/+7N4FSO9LtbZhNmQx
// Website: https://rickroll-token.netlify.app/

pragma solidity ^0.8.0;


contract RickRoll is ERC20 {
    constructor(uint256 _totalSupply) ERC20("RickRoll", "RickRoll") {
        _mint(msg.sender, _totalSupply);
    }
}