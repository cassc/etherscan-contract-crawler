// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import { IWorldsSharedMarket } from "../../interfaces/internal/IWorldsSharedMarket.sol";

import { MAX_WORLD_TAKE_RATE } from "../shared/Constants.sol";

import { WorldsUserRoles } from "./WorldsUserRoles.sol";

error WorldsPaymentInfo_Cannot_Set_Zero_Payment_Address();
error WorldsPaymentInfo_Exceeds_Max_World_Take_Rate(uint256 maxTakeRate);
error WorldsPaymentInfo_Payment_Address_Already_Set();

/**
 * @title Defines payment details to be used for a World.
 * @author HardlyDifficult, reggieag
 */
abstract contract WorldsPaymentInfo is IWorldsSharedMarket, ERC721Upgradeable, WorldsUserRoles {
  struct PaymentInfo {
    // Slot 0
    uint16 defaultTakeRateInBasisPoints;
    address payable paymentAddress;
    // (94-bits free space)
  }

  /// @notice Stores payment details for each World.
  mapping(uint256 worldId => PaymentInfo takeRateInfo) private $worldIdToPaymentInfo;

  ////////////////////////////////////////////////////////////////
  // Events
  ////////////////////////////////////////////////////////////////

  /**
   * Emitted when the default take rate for a World is assigned.
   * @param worldId The ID of the World.
   * @param defaultTakeRateInBasisPoints The default take rate for the World, in basis points.
   */
  event DefaultTakeRateSet(uint256 indexed worldId, uint16 defaultTakeRateInBasisPoints);

  /**
   * @notice Emitted when the payment address is set.
   * @param worldId The ID of the World.
   * @param paymentAddress The payment address for the World.
   */
  event PaymentAddressSet(uint256 indexed worldId, address indexed paymentAddress);

  ////////////////////////////////////////////////////////////////
  // Setup
  ////////////////////////////////////////////////////////////////

  /// @notice Called on mint of a new World to configure the default payment info.
  function _mintWorldsPaymentInfo(
    uint256 worldId,
    uint16 defaultTakeRateInBasisPoints,
    address payable paymentAddress
  ) internal {
    if (defaultTakeRateInBasisPoints > MAX_WORLD_TAKE_RATE) {
      revert WorldsPaymentInfo_Exceeds_Max_World_Take_Rate(MAX_WORLD_TAKE_RATE);
    }

    $worldIdToPaymentInfo[worldId].defaultTakeRateInBasisPoints = defaultTakeRateInBasisPoints;
    emit DefaultTakeRateSet(worldId, defaultTakeRateInBasisPoints);

    _setPaymentAddress(worldId, paymentAddress);
  }

  ////////////////////////////////////////////////////////////////
  // Payment address
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Set the payment address for the World.
   * @param worldId The ID of the World to set the payment address for.
   * @param paymentAddress The payment address for the World.
   */
  function setPaymentAddress(uint256 worldId, address payable paymentAddress) external onlyAdmin(worldId) {
    _setPaymentAddress(worldId, paymentAddress);
  }

  function _setPaymentAddress(uint256 worldId, address payable paymentAddress) private {
    if (paymentAddress == payable(address(0))) {
      revert WorldsPaymentInfo_Cannot_Set_Zero_Payment_Address();
    }
    if ($worldIdToPaymentInfo[worldId].paymentAddress == paymentAddress) {
      // Revert if the transaction is a no-op.
      revert WorldsPaymentInfo_Payment_Address_Already_Set();
    }

    $worldIdToPaymentInfo[worldId].paymentAddress = paymentAddress;

    emit PaymentAddressSet(worldId, paymentAddress);
  }

  /**
   * @notice Get the payment address for a World.
   * @param worldId The ID of the World to get the payment address for.
   * @return paymentAddress The payment address for the World.
   */
  function getPaymentAddress(uint256 worldId) public view returns (address payable paymentAddress) {
    paymentAddress = $worldIdToPaymentInfo[worldId].paymentAddress;
  }

  ////////////////////////////////////////////////////////////////
  // Take rate
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Get the default take rate for a World.
   * The actual take rate applied to sales may differ per inventory item listed with a World.
   * @param worldId The ID of the World to get the default take rate for.
   * @return defaultTakeRateInBasisPoints The default take rate for the World.
   */
  function getDefaultTakeRate(uint256 worldId) public view returns (uint16 defaultTakeRateInBasisPoints) {
    defaultTakeRateInBasisPoints = $worldIdToPaymentInfo[worldId].defaultTakeRateInBasisPoints;
  }

  ////////////////////////////////////////////////////////////////
  // Cleanup
  ////////////////////////////////////////////////////////////////

  function _burn(uint256 worldId) internal virtual override {
    // When a World is burned, remove the stored payment info.
    delete $worldIdToPaymentInfo[worldId];

    super._burn(worldId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[999] private __gap;
}