// contracts/OceanToken.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract MOON is ERC20{
    constructor(uint256 initialSupply) ERC20("MOON","MOON"){
        _mint(msg.sender, initialSupply);
    }
}