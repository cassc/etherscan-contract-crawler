// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS Delegation register interface.
 *
 */
interface IEPSDelegateRegister {
  // ======================================================
  // EVENTS
  // ======================================================
  // Emitted when a delegation container is created:
  event DelegationCreated(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed containerAddress,
    address owner,
    address delegate,
    uint96 fee,
    uint24 durationInDays,
    address tokenContract,
    uint256 tokenId,
    uint256 delegateRightsInteger
  );

  // Emitted when the delegation is accepted:
  event DelegationAccepted(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint32 endTime_,
    uint256 delegateRightsInteger_
  );

  // Emitted when the delegation is deleted:
  event DelegationDeleted(uint64 indexed provider, uint64 indexed delegationId);

  // Emitted when the delegation owner changed:
  event DelegationOwnerChanged(
    uint64 indexed provider,
    uint64 indexed delegationId
  );

  event DelegationContainerRelisted(
    uint64 provider,
    address container,
    uint64 oldId,
    uint64 newId
  );

  event ContainerListedForSale(
    uint64 provider,
    uint64 delegationId,
    address container,
    uint96 salePrice
  );

  event DelegationListedForSale(
    uint64 provider,
    uint64 delegationId,
    uint96 salePrice
  );

  event OfferMade(
    uint64 provider,
    address collection,
    bool collectionOffer,
    uint256 tokenId,
    uint24 duration,
    uint32 expiry,
    uint96 offerAmount,
    uint256 delegateRightsRequested,
    address offerer
  );

  event OfferAccepted(uint64 provider, uint64 offerId);

  event OfferExpiryChanged(uint64 provider, uint64 offerId, uint32 offerExpiry);

  event TransferRights(
    address indexed from,
    address indexed to,
    address indexed tokenContract,
    uint256 tokenId,
    uint256 rightsInteger
  );

  // ======================================================
  // FUNCTIONS
  // ======================================================

  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_);

  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address);

  function getBalanceByRight(
    address tokenContract_,
    address queryAddress_,
    uint256 rightsIndex_
  ) external view returns (uint256);

  function saveDelegationRecord(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint32 endTime_,
    uint256 delegateRightsInteger_
  ) external payable;

  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_
  ) external;

  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_
  ) external;

  function deleteEntry(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  ) external;

  function containerListedForSale(uint64 provider_, uint96 salePrice_) external;

  function delegationListedForSale(uint64 provider_, uint96 salePrice_)
    external;

  function getDelegationIdForContainer(address container_)
    external
    view
    returns (uint64 delegationId_);

  function relistEntry(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_
  ) external;

  function acceptOfferToExistingContainer(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external payable;
}