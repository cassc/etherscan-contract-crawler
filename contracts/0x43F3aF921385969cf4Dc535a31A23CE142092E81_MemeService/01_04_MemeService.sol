// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./IERC20Burnable.sol";

contract MemeService is Context {
  // ============ Errors ============

  error InvalidCall();

  // ============ Constants ============

  IERC20Burnable public immutable MILK;

  // ============ Storage ============

  //mapping of address to how much milk they loaded
  mapping(address => uint256) private _balances;

  // ============ Deploy ============

  constructor(IERC20Burnable milk) {
    MILK = milk;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the loaded balance of the `owner`
   */
  function balanceOf(address owner) external view returns(uint256) {
    return _balances[owner];
  }

  // ============ Write Methods ============

  /**
   * @dev Loads a `recipient` balance given the milk `amount`
   */
  function load(address recipient, uint256 amount) external {
    address caller = _msgSender();
    //burn milk. muhahahaha
    MILK.burnFrom(caller, amount);
    //increase balance
    _balances[recipient] += amount;
  }
}