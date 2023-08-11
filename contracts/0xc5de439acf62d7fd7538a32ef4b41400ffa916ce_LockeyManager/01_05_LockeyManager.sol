// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title LockeyManager
 * @author Unlockd
 * @notice Defines the error messages emitted by the different contracts of the Unlockd protocol
 */
contract LockeyManager is Initializable {
  /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
  //////////////////////////////////////////////////////////////*/
  uint256 internal _lockeyDiscount;
  ILendPoolAddressesProvider internal _addressesProvider;
  uint256 internal _lockeyDiscountOnDebtMarket;
  /*//////////////////////////////////////////////////////////////
                          MODIFIERS
  //////////////////////////////////////////////////////////////*/
  modifier onlyPoolAdmin() {
    require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /*//////////////////////////////////////////////////////////////
                        INITIALIZERS
  //////////////////////////////////////////////////////////////*/
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /**
   * @dev Initializes the LockeyManager contract replacing the constructor
   * @param provider The address of the LendPoolAddressesProvider
   **/
  function initialize(ILendPoolAddressesProvider provider) public initializer {
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addressesProvider = provider;
  }

  /*//////////////////////////////////////////////////////////////
                        GETTERS & SETTERS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Sets the discountPercentage an allowed percentage for lockey holders
   * @param discountPercentage percentage allowed to deduct
   **/
  function setLockeyDiscountPercentage(uint256 discountPercentage) external onlyPoolAdmin {
    _lockeyDiscount = discountPercentage;
  }

  /**
   * @dev Returns the lockey discount percentage
   **/
  function getLockeyDiscountPercentage() external view returns (uint256) {
    return _lockeyDiscount;
  }

  /**
   * @dev Sets the discountPercentageOnDebtMarket an allowed percentage for lockey holders
   * @param discountPercentage percentage allowed to deduct
   **/
  function setLockeyDiscountPercentageOnDebtMarket(uint256 discountPercentage) external onlyPoolAdmin {
    _lockeyDiscountOnDebtMarket = discountPercentage;
  }

  /**
   * @dev Returns the lockey discount percentage on debt market
   **/
  function getLockeyDiscountPercentageOnDebtMarket() external view returns (uint256) {
    return _lockeyDiscountOnDebtMarket;
  }
}