// SPDX-License-Identifier: MIT
// EPSP Contracts v2.0.0

pragma solidity 0.8.16;

/**
 *
 * @dev The EPS Delegation container contract interface. Lightweight interface with just the functions required
 * by the register contract.
 *
 */
interface IDelegationContainer {
  event OwnershipTransferred(
    uint64 provider,
    address indexed previousOwner,
    address indexed newOwner
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event EPSRegisterCallError(bytes reason);

  /**
   * @dev initialiseDelegationContainer - function to call to set storage correctly on a new clone:
   */
  function initialiseDelegationContainer(
    address payable owner_,
    address payable delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 ownerRightsInteger,
    string memory containerURI_,
    uint64 offerId
  ) external;

  /**
   * @dev Delegate accepts delegation
   */
  function acceptDelegation(uint64 provider_) external payable;

  /**
   * @dev Get delegation details.
   */
  function getDelegationContainerDetails(uint64 passedDelegationId_)
    external
    view
    returns (
      uint64 delegationId_,
      address assetOwner_,
      address delegate_,
      address tokenContract_,
      uint256 tokenId_,
      bool terminated_,
      uint32 startTime_,
      uint24 durationInDays_,
      uint96 delegationFee_,
      uint256 delegateRightsInteger_,
      uint96 containerSalePrice_,
      uint96 delegationSalePrice_
    );
}