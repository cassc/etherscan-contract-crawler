// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSProxyRegister {
  // ======================================================
  // ENUMS
  // ======================================================
  // enum for available proxy statuses
  enum ProxyStatus {
    none,
    pendingAcceptance,
    pendingPayment,
    live
  }

  // enum for participant
  enum Participant {
    hot,
    cold
  }

  // ======================================================
  // STRUCTS
  // ======================================================

  // Full proxy record
  struct Record {
    // Slot 1: 64 + 8 + 8 + 160 = 240
    uint64 provider;
    ProxyStatus status;
    bool feePaid;
    address cold;
    // Slot 2: 160
    address delivery;
  }

  // ======================================================
  // EVENTS
  // ======================================================

  // Emitted when an hot address nominates a cold address:
  event NominationMade(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint256 provider
  );

  // Emitted when a cold accepts a nomination from a hot address:
  event NominationAccepted(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint64 indexed provider
  );

  // Emitted when a proxy goes live
  event ProxyRecordLive(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint64 indexed provider
  );

  // Emitted when the delivery address is updated on a record:
  event DeliveryUpdated(
    address indexed hot,
    address indexed cold,
    address indexed delivery,
    address oldDelivery,
    uint256 provider
  );

  // Emitted when a register record is deleted. initiator 0 = cold, 1 = hot:
  event RecordDeleted(
    Participant initiator,
    address indexed hot,
    address indexed cold,
    uint256 provider
  );

  // ======================================================
  // ERRORS
  // ======================================================

  error NoPaymentPendingForAddress();
  error NoRecordFoundForAddress();
  error OnlyHotAddressCanChangeAddress();

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev Return if a cold wallet is live
   */
  function coldIsLive(address cold_) external view returns (bool);

  /**
   * @dev Return if a hot wallet is live
   */
  function hotIsLive(address hot_) external view returns (bool);

  /**
   * @dev Get proxy details for a hot address
   */
  function getProxyRecordForHot(address hot_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Get proxy details for a cold address
   */
  function getProxyRecordForCold(address cold_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Get proxy details for a cold address
   */
  function getProxyRecordForAddress(address queryAddress_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Returns the current role of a given address
   */
  // function getRole(address roleAddress_) external view returns (Role);

  // ======================================================
  // LIFECYCLE - NOMINATION
  // ======================================================

  /**
   * @dev nominate: Hot Nominates cold, direct contract call
   */
  function nominate(
    address cold_,
    address delivery_,
    uint64 provider_
  ) external payable;

  /**
   * @dev acceptNomination: Cold accepts nomination, direct contract call
   * (though it is anticipated that most will use an ERC20 transfer)
   */
  function acceptNomination(address hot_, uint64 provider_) external payable;

  // ======================================================
  // LIFECYCLE - CHANGING DELIVERY ADDRESS
  // ======================================================

  /**
   * @dev updateDeliveryAddress: Change delivery address on an existing proxy record.
   */
  function updateDeliveryAddress(address delivery_, uint256 provider_) external;

  // ======================================================
  // LIFECYCLE - DELETING A RECORD
  // ======================================================

  /**
   * @dev deleteRecord: Delete a proxy record, if found
   */
  function deleteRecord(uint256 provider_) external;

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================

  /**
   * @dev setRegisterFee: set the fee for accepting a registration:
   */
  function setRegisterFee(uint256 registerFee_) external;

  /**
   * @dev setDeletionNominalEth: set the nominal ETH transfer that represents an address ending a proxy
   */
  function setDeletionNominalEth(uint256 deleteNominalEth_) external;
}