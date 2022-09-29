// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ColtisToken is Ownable, ERC20 {
    constructor(address _tokenAllocation) ERC20 ("Coltis","COLTIS") {
        _mint(address(this), 150000000*(10** uint256(decimals())));
        _approve(address(this), _tokenAllocation, totalSupply());
        _transfer(address(this), _tokenAllocation, totalSupply());
    }
}