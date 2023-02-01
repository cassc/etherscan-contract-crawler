//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sheer is ERC20{
    constructor () ERC20("Sheer Finance Token", "SHRF"){
         _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}