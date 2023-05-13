// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


/**
 * @title DATBOI Token
 * @dev A meme token for the DATBOI community, made with love for the meme culture. 🐸
 * Website: dat-boi.xyz
**/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DATBOI is ERC20 {
   
    uint256 constant SUPPLY=555555555555555 * 10**18;

    constructor() ERC20("DATBOI", "DATBOI"){
        _mint(msg.sender,SUPPLY);
    }

}