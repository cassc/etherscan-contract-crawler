// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PNDC is ERC20 {
    constructor() ERC20("PNDC", "Pond Coin") {
        uint256 tokenSupply = 1000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}