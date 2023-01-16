// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JinniToken is ERC20, Ownable{
    constructor() ERC20("Jinni AI", "JINNI"){
        _mint(msg.sender,10000000000*10**18);
    }
}