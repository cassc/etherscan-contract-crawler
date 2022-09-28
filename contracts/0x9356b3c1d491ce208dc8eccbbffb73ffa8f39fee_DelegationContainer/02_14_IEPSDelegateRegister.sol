// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

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
    uint256 delegateRightsInteger,
    string URI
  );

  // Emitted when the delegation is accepted:
  event DelegationAccepted(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address container,
    address tokenContract,
    uint256 tokenId,
    address owner,
    address delegate,
    uint64 endTime,
    uint256 delegateRightsInteger,
    uint256 epsFee,
    string URI
  );

  // Emitted when a delegation is complete:
  event DelegationComplete(uint64 indexed delegationId);

  // Emitted when the delegation owner changes:
  event DelegationOwnerChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newOwner,
    uint256 epsFee
  );

  // Emitted when the delegation delegate changes:
  event DelegationDelegateChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newDelegate,
    uint256 epsFee
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
    uint64 offerId,
    address collection,
    bool collectionOffer,
    uint256 tokenId,
    uint24 duration,
    uint32 expiry,
    uint96 offerAmount,
    uint256 delegateRightsRequested,
    address offerer
  );

  event OfferAccepted(
    uint64 provider,
    uint64 offerId,
    uint256 epsFee,
    address epsFeeToken
  );

  event OfferDeleted(uint64 provider, uint64 offerId);

  event OfferChanged(
    uint64 provider,
    uint64 offerId,
    uint24 duration,
    uint32 offerExpiry,
    uint96 offerAmount,
    uint256 delegateRightsInteger
  );

  event TransferRights(
    address indexed from,
    address indexed to,
    address indexed tokenContract,
    uint256 tokenId,
    uint256 rightsInteger
  );

  event ContainerDetailsUpdated(
    uint64 provider,
    uint64 delegationId,
    address container,
    address delegate,
    uint256 fee,
    uint256 duration,
    uint256 delegateRightsInteger
  );

  event SundryEvent(
    uint64 provider,
    uint64 delegationId,
    address address1,
    address address2,
    uint256 integer1,
    uint256 integer2,
    uint256 integer3,
    uint256 integer4
  );

  // ======================================================
  // ERRORS
  // ======================================================

  error TemplateContainerLocked();
  error InvalidContainer();
  error InvalidERC20();
  error DoNoMintToThisAddress();
  error InvalidRights();
  error OwnerCannotBeDelegate();
  error CallerIsNotOfferMaker();
  error InvalidOffer();
  error MarketPlacePaused();

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
    uint64 endTime_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external payable;

  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee
  ) external;

  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external;

  function deleteEntry(
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
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external;

  function acceptOfferAfterDelegationCompleted(
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

  function containerDetailsUpdated(
    uint64 provider_,
    address delegate_,
    uint256 fee_,
    uint256 duration_,
    uint256 delegateRightsInteger_
  ) external;

  function acceptOfferPriorToCommencement(
    uint64 provider_,
    address owner_,
    address delegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external;

  function sundryEvent(
    uint64 provider_,
    address address1_,
    address address2_,
    uint256 int1_,
    uint256 int2_,
    uint256 int3_,
    uint256 int4_
  ) external;
}