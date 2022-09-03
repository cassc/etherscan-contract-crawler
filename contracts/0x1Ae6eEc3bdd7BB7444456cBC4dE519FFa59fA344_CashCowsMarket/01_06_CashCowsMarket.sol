// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-------------------------------------------------------------------------------------------
//
//   /$$$$$$                      /$$              /$$$$$$                                   
//  /$$__  $$                    | $$             /$$__  $$                                  
// | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$       | $$  \__/  /$$$$$$  /$$  /$$  /$$  /$$$$$$$
// | $$       |____  $$ /$$_____/| $$__  $$      | $$       /$$__  $$| $$ | $$ | $$ /$$_____/
// | $$        /$$$$$$$|  $$$$$$ | $$  \ $$      | $$      | $$  \ $$| $$ | $$ | $$|  $$$$$$ 
// | $$    $$ /$$__  $$ \____  $$| $$  | $$      | $$    $$| $$  | $$| $$ | $$ | $$ \____  $$
// |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/|  $$$$$/$$$$/ /$$$$$$$/
//  \______/  \_______/|_______/ |__/  |__/       \______/  \______/  \_____/\___/ |_______/
//
//-------------------------------------------------------------------------------------------
//
// Moo.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../IERC20MintableBurnable.sol";

// ============ Contract ============

/**
 * @dev This is the exchange $MILK for $DOLLA
 */
contract CashCowsMarket is Context, Ownable {
  using Address for address;

  // ============ Errors ============

  error InvalidCall();

  // ============ Constants ============

  IERC20MintableBurnable public immutable MILK;
  IERC20MintableBurnable public immutable DOLLA;

  // ============ Storage ============

  //this is the exchange rate for 1 milk (1 MILK:X DOLLA)
  uint256 private _exchangeRate = 100 ether;

  // ============ Deploy ============

  constructor(
    IERC20MintableBurnable milk, 
    IERC20MintableBurnable dolla
  ) {
    MILK = milk;
    DOLLA = dolla;
  }

  // ============ Write Methods ============

  /**
   * @dev Swaps milk for dolla
   */
  function toDolla(uint256 milk) external {
    address owner = _msgSender();
    //burn milk
    MILK.burnFrom(owner, milk);
    //mint dolla
    DOLLA.mint(owner, milk * _exchangeRate);
  }

  /**
   * @dev Swaps dolla for milk
   */
  function toMilk(uint256 dolla) external {
    address owner = _msgSender();
    //burn dolla
    DOLLA.burnFrom(owner, dolla);
    //mint milk
    MILK.mint(owner, dolla / _exchangeRate);
  }

  // ============ Admin Methods ============

  function setExchangeRate(uint256 rate) external onlyOwner {
    _exchangeRate = rate;
  }
}