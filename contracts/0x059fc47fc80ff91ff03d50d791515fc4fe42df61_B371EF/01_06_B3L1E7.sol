// SPDX-License-Identifier: MIT

/*

INVERT EVERYTHING YOU KNOW
rebatecoin.io

Free Airdrop for true believers.



*/
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract B371EF is ERC20, Ownable {
    constructor() ERC20("B371EF", "B371EF") {
        _mint(msg.sender, 1000000000000000000000000);
    }

}