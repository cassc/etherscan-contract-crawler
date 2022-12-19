// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS Delegation register interface.
 *
 */
interface IERC721DelegateRegister {
  // ======================================================
  // EVENTS
  // ======================================================

  struct DelegationRecord {
    // The unique identifier for every delegation. Note that this is stamped on each delegation container. This doesn't mean
    // that every delegation Id will make it to the register, as this might be a proposed delegation that is not taken
    // up by anyone.
    uint64 delegationId; // 64
    // The owner of the asset that is being containerised for delegation.
    address owner; // 160
    // The end time for this delegation. After the end time the owner can remove the asset.
    uint64 endTime; // 64
    // The address of the delegate for this delegation
    address delegate; // 160
    // Delegate rights integer:
    uint256 delegateRightsInteger;
  }

  struct DelegationParameters {
    // The provider who has originated this delegation.
    uint64 provider; // 64
    // The address proposed as deletage. The owner of an asset can specify a particular address OR they can leave
    // this as address 0 if they will accept any delegate, subject to payment of the fee (if any)
    address delegate; // 160
    // The duration of the delegation.
    uint24 duration; // 24
    // The fee that the delegate must pay for this delegation to go live.
    uint96 fee; // 96
    // Owner rights integer:
    uint256 ownerRightsInteger;
    // Delegate rights integer:
    uint256 delegateRightsInteger;
    // URI
    string URI;
    // Offer ID, passed if this is accepting an offer, otherwise will be 0:
    uint64 offerId;
  }

  struct Offer {
    // Slot 1 160 + 24 + 32 + 8 = 224
    // The address that is making the offer
    address offerMaker; // 160
    // The delegation duration time in days for this offer.
    uint24 delegationDuration; //24
    // When this offer expires
    uint32 expiry; // 32
    // Boolean to note a collection offer
    bool collectionOffer; // 8
    // Slot 2 160 + 96 = 256
    // The collection the offer is for
    address collection;
    // Offer amount (in provided ERC)
    uint96 offerAmount;
    // Slot 3 = 256
    // TokenId, (is ignored for collection offers)
    uint256 tokenId;
    // Slot 4 = 256
    // Delegate rights integer that they are requesting:
    uint256 delegateRightsInteger;
    // ERC20 that they are paying in:
    address paymentERC20;
  }

  // Configurable payment options for offers:
  struct ERC20PaymentOptions {
    bool isValid;
    uint96 registerFee;
  }

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

  function getRightsCodesByTokenContract(address tokenContract_)
    external
    view
    returns (string[16] memory rightsCodes_);

  function getRightsCodes()
    external
    view
    returns (string[16] memory rightsCodes_);

  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_);

  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) external view returns (address[] memory containers_);

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

  function containeriseForDelegation(
    address tokenContract_,
    uint256 tokenId_,
    DelegationParameters memory delegationData_
  ) external;

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

  function containerToDelegationId(address container_)
    external
    view
    returns (uint64 delegationId_);

  function delegationRegisterFee() external view returns (uint96);

  function delegationFeePercentage() external view returns (uint32);

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