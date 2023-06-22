// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token1 is ERC20, Ownable {

    constructor(uint256 _totalSupply, address _owner, address _supplyRecipient) ERC20("Token1", "TKN1") {
        
        _mint(_supplyRecipient, _totalSupply); // for deployer use msg.sender
        _transferOwnership(_owner);
    }

}