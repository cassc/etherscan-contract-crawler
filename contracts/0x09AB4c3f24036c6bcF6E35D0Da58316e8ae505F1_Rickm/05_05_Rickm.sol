//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './ERC20.sol';

contract Rickm is ERC20
{   
    constructor(uint256 _totalSupply) ERC20("Rickm", "RICKM") 
    {
        _mint(msg.sender, _totalSupply);
    }
}