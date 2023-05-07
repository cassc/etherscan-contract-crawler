// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RueToken is Ownable, ERC20 {

 constructor(uint256 _totalSupply) ERC20("Rue", "RUE") {
 _mint(msg.sender, _totalSupply);
 }

 function burn(uint256 value) external {
 _burn(msg.sender, value);
 }
}