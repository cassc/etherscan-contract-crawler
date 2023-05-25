pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathToken is ERC20Capped, Ownable {
    constructor(uint256 _initialSupply) ERC20("PathDao", "PATH") ERC20Capped(1000000000*10**18){
        ERC20._mint(msg.sender, _initialSupply);
    }

    function mint(address _to, uint256 _amount) onlyOwner external {
        _mint(_to, _amount);
    }
}