//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Alex1 is ERC20, Ownable {
    uint256 public totalSupplyLimit = 100000000*10**18;

    constructor(address mintAddress) ERC20("Alex1", "Alex1") {
        mint(mintAddress, totalSupplyLimit);
    }

    function mint(address mintAddress, uint256 _amount) internal onlyOwner {
        require(totalSupply() + _amount <= totalSupplyLimit, "ERC20: Can't mint exceed the total supply limit");
        _mint(mintAddress , _amount);
    }
}