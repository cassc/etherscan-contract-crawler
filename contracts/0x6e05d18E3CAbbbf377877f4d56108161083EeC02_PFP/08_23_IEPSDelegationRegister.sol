// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS Delegation Register - Interface

 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IOAT.sol";
import "./IERCOmnReceiver.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSDelegationRegister {
  // ======================================================
  // ENUMS and STRUCTS
  // ======================================================

  // Scope of a delegation: global, collection or token
  enum DelegationScope {
    global,
    collection,
    token
  }

  // Time limit of a delegation: eternal or time limited
  enum DelegationTimeLimit {
    eternal,
    limited
  }

  // The Class of a delegation: primary, secondary or rental
  enum DelegationClass {
    primary,
    secondary,
    rental
  }

  // The status of a delegation:
  enum DelegationStatus {
    live,
    pending
  }

  // Data output format for a report (used to output both hot and cold
  // delegation details)
  struct DelegationReport {
    address hot;
    address cold;
    DelegationScope scope;
    DelegationClass class;
    DelegationTimeLimit timeLimit;
    address collection;
    uint256 tokenId;
    uint40 startDate;
    uint40 endDate;
    bool validByDate;
    bool validBilaterally;
    bool validTokenOwnership;
    bool[25] usageTypes;
    address key;
    uint96 controlInteger;
    bytes data;
    DelegationStatus status;
  }

  // Delegation record
  struct DelegationRecord {
    address hot;
    uint96 controlInteger;
    address cold;
    uint40 startDate;
    uint40 endDate;
    DelegationStatus status;
  }

  // If a delegation is for a collection, or has additional data, it will need to read the delegation metadata
  struct DelegationMetadata {
    address collection;
    uint256 tokenId;
    bytes data;
  }

  // Details of a hot wallet lock
  struct LockDetails {
    uint40 lockStart;
    uint40 lockEnd;
  }

  // Validity dates when checking a delegation
  struct ValidityDates {
    uint40 start;
    uint40 end;
  }

  // Delegation struct to hold details of a new delegation
  struct Delegation {
    address hot;
    address cold;
    address[] targetAddresses;
    uint256 tokenId;
    bool tokenDelegation;
    uint8[] usageTypes;
    uint40 startDate;
    uint40 endDate;
    uint16 providerCode;
    DelegationClass delegationClass;
    uint96 subDelegateKey;
    bytes data;
    DelegationStatus status;
  }

  // Addresses associated with a delegation check
  struct DelegationCheckAddresses {
    address hot;
    address cold;
    address targetCollection;
  }

  // Classes associated with a delegation check
  struct DelegationCheckClasses {
    bool secondary;
    bool rental;
    bool token;
  }

  // Migrated record data
  struct MigratedRecord {
    address hot;
    address cold;
  }

  // ======================================================
  // CUSTOM ERRORS
  // ======================================================

  error UsageTypeAlreadyDelegated(uint256 usageType);
  error CannotDeleteValidDelegation();
  error CannotDelegatedATokenYouDontOwn();
  error IncorrectAdminLevel(uint256 requiredLevel);
  error OnlyParticipantOrAuthorisedSubDelegate();
  error HotAddressIsLockedAndCannotBeDelegatedTo();
  error InvalidDelegation();
  error ToMuchETHForPendingPayments(uint256 sent, uint256 required);
  error UnknownAmount();
  error InvalidERC20Payment();
  error IncorrectProxyRegisterFee();
  error UnrecognisedEPSAPIAmount();
  error CannotRevokeAllForRegisterAdminHierarchy();

  // ======================================================
  // EVENTS
  // ======================================================

  event DelegationMade(
    address indexed hot,
    address indexed cold,
    address targetAddress,
    uint256 tokenId,
    bool tokenDelegation,
    uint8[] usageTypes,
    uint40 startDate,
    uint40 endDate,
    uint16 providerCode,
    DelegationClass delegationClass,
    uint96 subDelegateKey,
    bytes data,
    DelegationStatus status
  );
  event DelegationRevoked(address hot, address cold, address delegationKey);
  event DelegationPaid(address delegationKey);
  event AllDelegationsRevokedForHot(address hot);
  event AllDelegationsRevokedForCold(address cold);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   *
   *
   * @dev getDelegationRecord
   *
   *
   */
  function getDelegationRecord(address delegationKey_)
    external
    view
    returns (DelegationRecord memory);

  /**
   *
   *
   * @dev isValidDelegation
   *
   *
   */
  function isValidDelegation(
    address hot_,
    address cold_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (bool isValid_);

  /**
   *
   *
   * @dev getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   *
   *
   */
  function getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (address[] memory addresses_);

  /**
   *
   *
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance
   *
   *
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address contractAddress_,
    uint256 usageType_,
    bool erc1155_,
    uint256 id_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (uint256 balance_);

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(
    address collection_,
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    external
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    );

  /**
   *
   *
   * @dev delegationFromColdExists - check a cold delegation exists
   *
   *
   */
  function delegationFromColdExists(address cold_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev delegationFromHotExists - check a hot delegation exists
   *
   *
   */
  function delegationFromHotExists(address hot_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev getAllForHot - Get all delegations at a hot address, formatted nicely
   *
   *
   */
  function getAllForHot(address hot_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev getAllForCold - Get all delegations at a cold address, formatted nicely
   *
   *
   */
  function getAllForCold(address cold_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev makeDelegation - A direct call to setup a new proxy record
   *
   *
   */
  function makeDelegation(
    address hot_,
    address cold_,
    address[] memory targetAddresses_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint8[] memory usageTypes_,
    uint40 startDate_,
    uint40 endDate_,
    uint16 providerCode_,
    DelegationClass delegationClass_, //0 = primary, 1 = secondary, 2 = rental
    uint96 subDelegateKey_,
    bytes memory data_
  ) external payable;

  /**
   *
   *
   * @dev getDelegationKey - get the link hash to the delegation metadata
   *
   *
   */
  function getDelegationKey(
    address hot_,
    address cold_,
    address targetAddress_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint96 controlInteger_,
    uint40 startDate_,
    uint40 endDate_
  ) external pure returns (address);

  /**
   *
   *
   * @dev getHotAddressLockDetails
   *
   *
   */
  function getHotAddressLockDetails(address hot_)
    external
    view
    returns (LockDetails memory, address[] memory);

  /**
   *
   *
   * @dev lockAddressUntilDate
   *
   *
   */
  function lockAddressUntilDate(uint40 unlockDate_) external;

  /**
   *
   *
   * @dev lockAddress
   *
   *
   */
  function lockAddress() external;

  /**
   *
   *
   * @dev unlockAddress
   *
   *
   */
  function unlockAddress() external;

  /**
   *
   *
   * @dev addLockBypassAddress
   *
   *
   */
  function addLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev removeLockBypassAddress
   *
   *
   */
  function removeLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev revokeRecord: Revoking a single record with Key
   *
   *
   */
  function revokeRecord(address delegationKey_, uint96 subDelegateKey_)
    external;

  /**
   *
   *
   * @dev revokeGlobalAll
   *
   *
   */
  function revokeRecordOfGlobalScopeForAllUsages(address participant2_)
    external;

  /**
   *
   *
   * @dev revokeAllForCold: Cold calls and revokes ALL
   *
   *
   */
  function revokeAllForCold(address cold_, uint96 subDelegateKey_) external;

  /**
   *
   *
   * @dev revokeAllForHot: Hot calls and revokes ALL
   *
   *
   */
  function revokeAllForHot() external;

  /**
   *
   *
   * @dev deleteExpired: ANYONE can delete expired records
   *
   *
   */
  function deleteExpired(address delegationKey_) external;

  /**
   *
   *
   * @dev setRegisterFee: set the fee for accepting a registration:
   *
   *
   */
  function setRegisterFees(
    uint256 registerFee_,
    address erc20_,
    uint256 erc20Fee_
  ) external;

  /**
   *
   *
   * @dev setRewardTokenAndRate
   *
   *
   */
  function setRewardTokenAndRate(address rewardToken_, uint88 rewardRate_)
    external;

  /**
   *
   *
   * @dev lockRewardRate
   *
   *
   */
  function lockRewardRate() external;

  /**
   *
   *
   * @dev setLegacyOff
   *
   *
   */
  function setLegacyOff() external;

  /**
   *
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   *
   */
  function setENSName(string memory ensName_) external;

  /**
   *
   *
   * @dev setENSReverseRegistrar
   *
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_) external;

  /**
   *
   *
   * @dev setTreasuryAddress: set the treasury address:
   *
   *
   */
  function setTreasuryAddress(address treasuryAddress_) external;

  /**
   *
   *
   * @dev setDecimalsAndBalance
   *
   *
   */
  function setDecimalsAndBalance(uint8 decimals_, uint256 balance_) external;

  /**
   *
   *
   * @dev withdrawETH: withdraw eth to the treasury:
   *
   *
   */
  function withdrawETH(uint256 amount_) external returns (bool success_);

  /**
   *
   *
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   *
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   *
   *
   * @dev isLevelAdmin
   *
   *
   */
  function isLevelAdmin(
    address receivedAddress_,
    uint256 level_,
    uint96 key_
  ) external view returns (bool);
}