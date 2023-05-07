/*

Telegram:
https://t.me/S33DOFPEPEERC

Website:
https://S33DOfPepe.live

Twitter:
https://twitter.com/S33DOFPEPE
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract S33D is ERC20, Ownable {
    constructor() ERC20("Seed Of Pepe", "S33D") {{
        _mint(msg.sender, 700000000000 * 10 ** decimals());
    }}

}