//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './ERC20.sol';

contract Xiansheng is ERC20
{   
    constructor(uint256 _totalSupply) ERC20("Xiansheng", "XIAN") 
    {
        _mint(msg.sender, _totalSupply);
    }
}