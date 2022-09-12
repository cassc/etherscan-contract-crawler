// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract Dai is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        _mint(msg.sender, _totalSupply);
        console.log(msg.sender);
    }
}

contract Link is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        _mint(msg.sender, _totalSupply);
        console.log(msg.sender);
    }
}

contract Comp is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        _mint(msg.sender, _totalSupply);
        console.log(msg.sender);
    }
}