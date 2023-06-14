// SPDX-License-Identifier: MIT
// Who is LEE ?

// Web: https://L-E-E.vip
// Telegram: https://t.me/LifeEvenEnd

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract LEE is ERC20, Ownable {
    uint256 maxSupply = 1000000000000000;
    
    constructor() ERC20("LIFE EVEN END", "LEE") {
        _mint(msg.sender, maxSupply * 10 ** decimals());
    }
}