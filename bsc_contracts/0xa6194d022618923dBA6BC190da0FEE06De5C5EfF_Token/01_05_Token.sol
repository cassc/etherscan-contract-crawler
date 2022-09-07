// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title Token
 * @dev Very HashGo ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract Token is ERC20 {
  uint256 private _totalSupply = 200000000 * (10 ** 18);

 constructor() ERC20("AII", "AII") {
      _mint(msg.sender,_totalSupply);
    }      

}