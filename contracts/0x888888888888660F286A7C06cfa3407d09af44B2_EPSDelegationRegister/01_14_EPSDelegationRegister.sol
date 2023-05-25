// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS Delegation Register. Features include: 

  * Primary, Secondary and Rental delegation classes.
    * Primary and Rental: only one delegation per global / collection / token / usage type combination.
    * Secondary: unlimited delegations (useful for many use cases, including consolidation).
  * Filter returned address lists to include only primary delegations, or include secondary and rental classes  
  * All delegations of primary and rental class are checked to ensure they are unique.
  * Sub-delegation.
    * A sub-delegate can add new delegations for the cold wallet. The internal delegation framework forms a structured auth model.
  * Consolidation.
    * Through matching secondary delegations (0xA to 0xB and 0xB to 0xA) we consolidate the usages for two addresses together.
  * Revoke from hot and cold in 0(1) time.
  * Revoke for all.
    * Both hot and cold can revoke for all with minimal gas (about 40k).
  * Multiple usages per delegation
    * Each delegation can have 1 to 25 usages, all stored in a single slot.
  * Multiple collection delegations per call
    * A single delegation call can set up delegations for n collections.
  * Structured ‘Delegation Report’ by address
    * For hot and cold wallets
  * Delegation locking
    * Set by the hot address, can be time bound or not
    * Hot addresses can unlock for a time period (e.g. unlock for the next five minutes). The lock automatically reinstates, no call or gas required.
  * Delegation lock bypass list
    * A hot wallet can load a list of addresses that can bypass the lock. For example, they can lock but add that 0xC can bypass the lock
  * Default descriptions for usage codes
  * Project specific descriptions for usage codes that can be set by admin or collection owners
  * Contract uses sub-delegation and delegation as its own internal auth model, allowing a structured approach to multi-user admin.
  * beneficiaryOf function: return the beneficiary of a token given a usage code
  * beneficiaryBalanceOf function: return the beneficiary balance for an address.
  * Both of the above can be filtered to include primary, secondary or rental delegation classes.
    * A useful method: beneficiaryBalanceOf for just primary classes is a very simple API for projects to implement
  * Headless protocol can:
    * Make a global delegation for any or all usage types
    * Make a collection specific delegation for any or all usage types
    * Revoke from hot
    * Revoke from cold
    * Revoke a token delegation
    * Revoke all for hot
    * Revoke all for cold
    * Lock a hot wallet
    * Unlock a hot wallet
  * Many view functions, including:
    * All addresses for a hot wallet, filtered by primary, secondary, rental
    * Address lock details
    * Validity status for a delegation
    * Whether a delegation from / to an address exists
    * All delegation keys for a hot or cold address (each delegation has a unique key which is the first 20 bytes of the hash of the delegation arguments)
    * If a cold or hot delegation exists for an address (in 0(1) time).
 */

// Usage list:
// 1) All
// 2) Minting / Allowlist
// 3) Airdrops
// 4) Voting / Governance
// 5) Avatar Display
// 6) Social Media
// 7) Physical Events Access
// 8) Virtual Events Access
// 9) Club / Community Access
// 10) Metaverse Access
// 11) Metaverse Land
// 12) Gameplay
// 13) IP Licensing
// 14) Sub-delegation
// 15) Merch / Digital Assets
// 16) -- currently vacant
// 17) -- currently vacant
// 18) -- currently vacant
// 19) -- currently vacant
// 20) -- currently vacant
// 21) -- currently vacant
// 22) -- currently vacant
// 23) -- community reserved
// 24) -- community reserved
// 25) -- community reserved

pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IEPSDelegationRegister.sol";
import "../Utils/ENSReverseRegistrar.sol";

contract EPSDelegationRegister is
  Context,
  IEPSDelegationRegister,
  IERCOmnReceiver
{
  using EnumerableSet for EnumerableSet.AddressSet;

  // ======================================================
  // CONSTANTS
  // ======================================================

  // Delegation Scopes control integers:
  uint96 private constant COLLECTION_DELEGATION = 1 * (10**27);
  uint96 private constant TOKEN_DELEGATION = 2 * (10**27);

  // Delegation Classes control integers:
  uint96 private constant TIME_BASED_DELEGATION = 1 * (10**26);
  uint96 private constant SECONDARY_DELEGATION = 1 * (10**25);
  uint96 private constant RENTAL_DELEGATION = 2 * (10**25);

  // Number of positions in the control integer:
  uint256 private constant LENGTH_OF_CONTROL_INTEGER = 29;

  // Number of usage types:
  uint256 private constant NUMBER_OF_USAGE_TYPES = 25;

  // Token API call transaction types:
  uint256 private constant MAKE_PRIMARY_DELEGATION = 1;
  uint256 private constant REVOKE = 2;
  uint256 private constant REVOKE_ALL_FOR_HOT = 3;
  uint256 private constant REVOKE_ALL_FOR_COLD = 4;
  uint256 private constant LOCK_HOT = 5;
  uint256 private constant UNLOCK_HOT = 6;
  uint256 private constant MAKE_SECONDARY_DELEGATION = 7;
  uint256 private constant MAKE_30_DAY_PRIMARY_DELEGATION = 8;
  uint256 private constant MAKE_90_DAY_PRIMARY_DELEGATION = 9;

  // Internal authority model
  uint256 private constant ALL_DELEGATION = 1;
  uint256 private constant SUB_DELEGATION = 14;
  uint256 private constant LEVEL_ONE = 25;
  uint256 private constant LEVEL_TWO = 24;
  uint256 private constant LEVEL_THREE = 23;
  uint96 private constant LEVEL_ONE_KEY = 11000000000000000000000000;
  uint96 private constant LEVEL_TWO_KEY = 10100000000000000000000000;
  uint96 private constant LEVEL_THREE_KEY = 10010000000000000000000000;
  address private constant INITIAL_ADMIN =
    0x9F0773aF2b1d3f7cC7030304548A823B4E6b13bB;

  IEPSDelegationRegister private constant LEGACY_REGISTER =
    IEPSDelegationRegister(0x88888888888806458312bB6B7Ae0f9a7ad30Ea40);

  // ======================================================
  // STORAGE
  // ======================================================

  // 'Air drop' of EPSAPI to every address
  uint256 private _epsAPIBalance = type(uint256).max;

  // Fee to add a live proxy record to the register. If a fee is required this must be sent either:
  // 1) On the call from the cold to nominate the hot,
  // 2) If the cold calls through the ERC20 API the record will be in a pending state until
  //    the eth payment has been made from the cold to the register address (note when there is no
  //    fee this step is never required).

  uint256 private _proxyRegisterFee;

  // Reward token details:
  IOAT public rewardToken;
  uint88 public rewardRate;
  bool public rewardRateLocked;

  // Load one item from legacy register?
  bool public includeLegacy = true;

  // Decimals
  uint8 private _decimals = 3;

  // ENS reverse registrar
  ENSReverseRegistrar private _ensReverseRegistrar;

  // EPS treasury address:
  address private _treasury;

  // Note that collection delegation 'overrides' global delegation. For example, address A delegates
  // to address B for all. Address A also delegates to address C for byWassies. When checking
  // for this delegation for byWassies address B will NOT have the delegation to address A, but address
  // C WILL. For all collections that are NOT byWassies address B will have the delegation from address A,
  // and address C will NOT.
  mapping(bytes32 => uint256) internal _delegationTypesForAddress;

  // The control integer tells us about the delegation, and is structured as follows:
  // 98765432129876543211987654321    29 integers per uint96
  // ^^^^^-----------------------^
  // ||||            | 25 Usage types
  // ||| DelegationClass: 0 = Primary, 1 = Secondary, 2 = Rental (position 26)
  // || DelegationTimeLimit: Is eternal or time limited. 0 = eternal, 1 = time limited (position 27)
  // | DelegationScope: Is global, collection or token. 0  = global, 1 = collection, 2 = token (position 28)
  // Reserved for transaction type on headless protocol calls (position 29)
  // Note that in token API calls positions 27 and 28 when received hold the provider code
  // Example 1: this is an entry that delegates primary for all rights for an unlimited time for all
  // collections:
  // 00000000000000000000000000001
  // Example 2: this is an entry that delegates secondary for all rights for an limited time for all
  // collections for usages 2, 3, 5 and 24:
  // 00110100000000000000000010110
  // Example 3: this is an entry that delegates rental for all rights for an unlimited time for all
  // collections:
  // 00020000000000000000000000001

  // Map addresses hashed with tranche to delegation key. The delegation key is the first 20 bytes of a hash
  // of the delegation data:
  mapping(bytes32 => EnumerableSet.AddressSet) internal _hotToDelegation;
  mapping(bytes32 => EnumerableSet.AddressSet) internal _coldToDelegation;
  mapping(bytes32 => EnumerableSet.AddressSet) internal _tokenToDelegation;

  // Map a delegation key to delegation record:
  mapping(address => DelegationRecord) private _delegationRecord;

  // Map a delegation record to it's metadata (if required).
  mapping(address => DelegationMetadata) public delegationMetadata;

  // Hot wallet delegation tranche number
  mapping(address => uint256) internal _hotWalletTranche;

  // Cold wallet delegation tranche number
  mapping(address => uint256) internal _coldWalletTranche;

  // Map an address to a lock struct
  mapping(address => LockDetails) private _addressLockDetails;

  // Map an address to a lock bypass list:
  mapping(address => EnumerableSet.AddressSet) internal _lockBypassList;

  // Map cold address to pending payments
  mapping(address => address[]) public pendingPayments;

  // ERC20 token relayed fee
  mapping(address => uint256) private _erc20PerTransactionFee;

  /**
   *
   *
   * @dev Constructor
   *
   *
   */
  constructor() {
    _addAuthority(SUB_DELEGATION);
    _addAuthority(LEVEL_ONE);
    _addAuthority(LEVEL_TWO);
    _addAuthority(LEVEL_THREE);
  }

  // ======================================================
  // MODIFIERS
  // ======================================================

  /**
   *
   *
   * @dev onlyLevelOneAdmin - functionality for level one admins
   *
   *
   */
  modifier onlyLevelOneAdmin() {
    if (!isLevelAdmin(_msgSender(), LEVEL_ONE, LEVEL_ONE_KEY)) {
      revert IncorrectAdminLevel(1);
    }
    _;
  }

  /**
   *
   *
   * @dev onlyLevelTwoAdmin - functionality for level two admins
   *
   *
   */
  modifier onlyLevelTwoAdmin() {
    if (!isLevelAdmin(_msgSender(), LEVEL_TWO, LEVEL_TWO_KEY)) {
      revert IncorrectAdminLevel(2);
    }
    _;
  }

  /**
   *
   *
   * @dev onlyLevelThreeAdmin - functionality for level three admins
   *
   *
   */
  modifier onlyLevelThreeAdmin() {
    if (!isLevelAdmin(_msgSender(), LEVEL_THREE, LEVEL_THREE_KEY)) {
      revert IncorrectAdminLevel(3);
    }
    _;
  }

  // ======================================================
  // GET DELEGATIONS
  // ======================================================

  /**
   *
   *
   * @dev getDelegationRecord - return the delegation record object for
   * the provided delegationKey argument
   *
   * @param delegationKey_ The address key for this delegation
   * @return DelegationRecord The delegation record for the passed key
   *
   *
   */
  function getDelegationRecord(address delegationKey_)
    external
    view
    returns (DelegationRecord memory)
  {
    return (_delegationRecord[delegationKey_]);
  }

  /**
   *
   *
   * @dev isValidDelegation - returns whether the arguments passed
   * result in a valid delegation
   *
   * @param hot_ The hot address for the delegation
   * @param cold_ The cold address for the delegation
   * @param collection_ The collection for the delegation. Note that address(0)
   * is passed for global delegations
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return isValid_ Whether this is valid (true) or not (false)
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
  ) external view returns (bool isValid_) {
    (, isValid_) = _getAddresses(
      hot_,
      collection_,
      usageType_,
      includeSecondary_,
      includeRental_,
      cold_
    );
    return (isValid_);
  }

  /**
   *
   *
   * @dev getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   * @param hot_ The hot address for the delegation
   * @param collection_ The collection for the delegation. Note that address(0)
   * is passed for global delegations
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return addresses_ An array of addresses valid for the passed arguments
   *
   *
   */
  function getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) public view returns (address[] memory addresses_) {
    (addresses_, ) = _getAddresses(
      hot_,
      collection_,
      usageType_,
      includeSecondary_,
      includeRental_,
      address(0)
    );
    return (addresses_);
  }

  /**
   *
   *
   * @dev _getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   *
   * @param hot_ The hot address for the delegation
   * @param collection_ The collection for the delegation. Note that address(0)
   * is passed for global delegations
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   * @param targetCold_ If we are looking for a specifc cold address this will be used
   * to determine the result of the isValid_ return parameter
   *
   * @return addresses_ An array of addresses valid for the passed arguments
   * @return isValid_ Whether this is valid (true) or not (false)
   *
   *
   */
  function _getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_,
    address targetCold_
  ) internal view returns (address[] memory addresses_, bool isValid_) {
    if (
      _includesUsageTypeOrAll(
        usageType_,
        _delegationTypesForAddress[
          _getDelegationTypeHash(hot_, collection_, false, 0)
        ]
      ) ||
      (collection_ != address(0) &&
        _includesUsageTypeOrAll(
          usageType_,
          _delegationTypesForAddress[
            _getDelegationTypeHash(hot_, address(0), false, 0)
          ]
        ))
    ) {
      // OK, so the hot_ address has delegated to another address for usage type for this
      // collection (or globally) for the PRIMARY. This means that
      // balances associated with the hot_ address will be represented on OTHER addresse(s) for PRIMARY
      // usage.

      // As 'rental' is also a primary scoped item we can only proceed if we were including secondary
      // delegations, and are therefore OK with multiple return results across the register for a
      // collection / usage type combination:
      if (!includeSecondary_) {
        return (new address[](0), false);
      }
    }

    uint256 delegationCount;
    uint256 addedAddressesCount;

    (
      addresses_,
      delegationCount,
      addedAddressesCount,
      isValid_
    ) = _getDelegations(
      DelegationCheckAddresses(hot_, targetCold_, collection_),
      usageType_,
      includeSecondary_,
      includeRental_
    );

    if (isValid_) {
      return (addresses_, isValid_);
    }

    if (delegationCount > addedAddressesCount) {
      assembly {
        let decrease := sub(delegationCount, addedAddressesCount)
        mstore(addresses_, sub(mload(addresses_), decrease))
      }
    }

    if (includeLegacy && addresses_.length == 1) {
      // One result is the calling hot (no delegations), so check legacy for ONE cold address delegation:

      address[] memory legacyRecords = LEGACY_REGISTER.getAddresses(
        hot_,
        collection_,
        usageType_,
        includeSecondary_,
        includeRental_
      );

      if (legacyRecords.length > 1) {
        // See if this cold has an entry on this register, as if it does it has been overriden
        // and won't be returned from the legacy register:

        if (
          _hasExistingDelegation(
            legacyRecords[1],
            address(0),
            false,
            0,
            usageType_
          ) ||
          _hasExistingDelegation(
            legacyRecords[1],
            collection_,
            false,
            0,
            usageType_
          )
        ) {
          // We have an overriding delegation on this register, do not include this
          return (addresses_, false);
        }

        if (legacyRecords[1] == targetCold_) {
          return (addresses_, true);
        }

        addresses_ = new address[](2);
        addresses_[0] = legacyRecords[0];
        addresses_[1] = legacyRecords[1];
      }
    }

    return (addresses_, false);
  }

  /**
   *
   *
   * @dev _hasExistingDelegation - return if the passed parameters resolve to an existing
   * delegaiton on this register
   *
   * @param cold_ The cold address for the delegation
   * @param collection_ The collection for the delegation. Note that address(0)
   * is passed for global delegations
   * @param tokenBased_ If this is a token based delegation (true) or not (false)
   * @param tokenId_ The token ID for token based delegations
   * @param usageType_ The usage type for the delegation
   *
   * @return bool If the passet arguments resolve to an existing delegation (true) ot
   * not (false)
   *
   *
   */
  function _hasExistingDelegation(
    address cold_,
    address collection_,
    bool tokenBased_,
    uint256 tokenId_,
    uint256 usageType_
  ) internal view returns (bool) {
    // Get the delegation types for this cold address with the collection scope
    uint256 currentDelegationTypes = _delegationTypesForAddress[
      _getDelegationTypeHash(cold_, collection_, tokenBased_, tokenId_)
    ];

    // Check if this cold address has delegated with collection scope for this usage type:
    if (
      currentDelegationTypes != 0 &&
      ((usageType_ == 1) ||
        _includesUsageTypeOrAll(usageType_, currentDelegationTypes))
    ) {
      // There is an existing delegation
      return (true);
    } else {
      // There is no existing delegation
      return (false);
    }
  }

  /**
   *
   *
   * @dev _getDelegations - Get delegations for the passed arguments
   *
   * @param checkAddresses_ An object holding the hot, cold and collection
   * addresses for this query
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return addresses_ The valid return addresses for this query
   * @return delegationCount_ How many delegations were queried
   * @return addedAddressesCount_ How many addresses were added to the return array
   * @return isValid_ If we are looking for a specific cold address this will
   * provide that information.
   *
   *
   *
   */
  function _getDelegations(
    DelegationCheckAddresses memory checkAddresses_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    internal
    view
    returns (
      address[] memory addresses_,
      uint256 delegationCount_,
      uint256 addedAddressesCount_,
      bool isValid_
    )
  {
    if (checkAddresses_.targetCollection == address(0)) {
      // We will only be looking for global delegations, collection level delegations will
      // not be relevant:
      return
        _getGlobalDelegations(
          checkAddresses_,
          usageType_,
          includeSecondary_,
          includeRental_
        );
    } else {
      return
        _getCollectionDelegations(
          checkAddresses_,
          usageType_,
          includeSecondary_,
          includeRental_
        );
    }
  }

  /**
   *
   *
   * @dev _getGlobalDelegations - Get global delegations for the passed arguments
   *
   * @param checkAddresses_ An object holding the hot, cold and collection
   * addresses for this query
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return addresses_ The valid return addresses for this query
   * @return possibleCount_ How many delegations were queried
   * @return actualCount_ How many addresses were added to the return array
   * @return isValid_ If we are looking for a specific cold address this will
   * provide that information.
   *
   *
   */
  function _getGlobalDelegations(
    DelegationCheckAddresses memory checkAddresses_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    internal
    view
    returns (
      address[] memory addresses_,
      uint256 possibleCount_,
      uint256 actualCount_,
      bool isValid_
    )
  {
    EnumerableSet.AddressSet storage delegationsToCheck = _hotToDelegation[
      _hotMappingKey(checkAddresses_.hot)
    ];

    unchecked {
      possibleCount_ = delegationsToCheck.length() + 1;

      addresses_ = new address[](possibleCount_);

      addresses_[0] = checkAddresses_.hot;

      actualCount_++;
    }

    for (uint256 i = 0; i < (possibleCount_ - 1); i++) {
      DelegationRecord memory currentDelegation = _delegationRecord[
        delegationsToCheck.at(i)
      ];

      if (
        // Only proceeed if this ISN'T a collection specific delegation:
        (_collectionSpecific(currentDelegation.controlInteger)) ||
        (
          !_delegationIsValid(
            DelegationCheckAddresses(
              checkAddresses_.hot,
              currentDelegation.cold,
              address(0)
            ),
            DelegationCheckClasses(includeSecondary_, includeRental_, false),
            currentDelegation.controlInteger,
            usageType_,
            0,
            ValidityDates(
              currentDelegation.startDate,
              currentDelegation.endDate
            ),
            delegationsToCheck.at(i)
          )
        )
      ) {
        continue;
      }

      if (currentDelegation.cold == checkAddresses_.cold) {
        return (addresses_, 0, 0, true);
      }

      // Made it here. Add it:
      addresses_[actualCount_] = currentDelegation.cold;

      unchecked {
        actualCount_++;
      }
    }

    return (addresses_, possibleCount_, actualCount_, false);
  }

  /**
   *
   *
   * @dev _getCollectionDelegations - get collection level delegations for the
   * passed arguments
   *
   * @param checkAddresses_ An object holding the hot, cold and collection
   * addresses for this query
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return addresses_ The valid return addresses for this query
   * @return possibleCount_ How many delegations were queried
   * @return actualCount_ How many addresses were added to the return array
   * @return isValid_ If we are looking for a specific cold address this will
   * provide that information.
   *
   *
   */
  function _getCollectionDelegations(
    DelegationCheckAddresses memory checkAddresses_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    internal
    view
    returns (
      address[] memory addresses_,
      uint256 possibleCount_,
      uint256 actualCount_,
      bool isValid_
    )
  {
    EnumerableSet.AddressSet storage delegationsToCheck = _hotToDelegation[
      _hotMappingKey(checkAddresses_.hot)
    ];

    unchecked {
      possibleCount_ = delegationsToCheck.length() + 1;

      addresses_ = new address[](possibleCount_);

      addresses_[0] = checkAddresses_.hot;

      actualCount_++;
    }

    // Slightly more complicated, as we have these possibilities:
    // 1) If the collection on the delegation matches the collection we have been
    // asked about then this is valid.
    // 2) If there is a collection on the delegation and it DOESN'T match the
    // collection we have been asked about then it is invalid.
    // 3) If there is no collection on the delegation (i.e. it is global) AND
    // there is no collection level delegation for the cold address it is valid
    // 4) If there is no collection on the delegation (i.e. it is global) AND
    // there IS a collection level delegation for the cold address it is INVALID,
    // as the specific collection delegation 'trumps' the global delegation.

    for (uint256 i = 0; i < (possibleCount_ - 1); i++) {
      DelegationRecord memory currentDelegation = _delegationRecord[
        delegationsToCheck.at(i)
      ];

      // Is this token specific? If so continue, as we do not return whole
      // address based delegations for token specific delegations. They can be
      // access through the beneficiaryOf method
      if (
        _delegationScope(currentDelegation.controlInteger) ==
        DelegationScope.token
      ) {
        continue;
      }

      address collectionToCheck = address(0);

      // Is this a collection specific delegation?
      if (_collectionSpecific(currentDelegation.controlInteger)) {
        collectionToCheck = checkAddresses_.targetCollection;
      } else {
        // Check if the cold address has a collection specific delegation for this collection:
        // Only proceed if there ISN'T a collection specific delegation for this usage type:
        if (
          _hasCollectionDelegation(
            currentDelegation.cold,
            checkAddresses_.targetCollection,
            usageType_
          )
        ) {
          continue;
        }
      }

      if (
        !_delegationIsValid(
          DelegationCheckAddresses(
            checkAddresses_.hot,
            currentDelegation.cold,
            collectionToCheck
          ),
          DelegationCheckClasses(includeSecondary_, includeRental_, false),
          currentDelegation.controlInteger,
          usageType_,
          0,
          ValidityDates(currentDelegation.startDate, currentDelegation.endDate),
          delegationsToCheck.at(i)
        )
      ) {
        continue;
      }

      if (currentDelegation.cold == checkAddresses_.cold) {
        return (addresses_, 0, 0, true);
      }

      // Made it here. Add it:
      addresses_[actualCount_] = currentDelegation.cold;

      unchecked {
        actualCount_++;
      }
    }
    return (addresses_, possibleCount_, actualCount_, false);
  }

  /**
   *
   *
   * @dev _hasCollectionDelegation - Return if this cold address has a
   * collection level delegation
   *
   * @param cold_ The cold address for the delegation
   * @param collection_ The collection for the delegation.
   * @param usageType_ The usage type for the delegation
   *
   * @return bool If this has a collection level delegation (true) or not (false)
   *
   *
   */
  function _hasCollectionDelegation(
    address cold_,
    address collection_,
    uint256 usageType_
  ) internal view returns (bool) {
    return (
      _includesUsageTypeOrAll(
        usageType_,
        _delegationTypesForAddress[
          _getDelegationTypeHash(cold_, collection_, false, 0)
        ]
      )
    );
  }

  /**
   *
   *
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance
   *
   * @param queryAddress_ The beneficiary address that we are querying
   * @param contractAddress_ The contract we are checking balances on
   * @param usageType_ The usage type for the delegation
   * @param erc1155_ If this is an 1155 contract
   * @param id_ If we have an 1155 contract to query this has the token Id
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return balance_ The balance for this beneficiary
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
  ) external view returns (uint256 balance_) {
    address[] memory delegatedAddresses = getAddresses(
      queryAddress_,
      contractAddress_,
      usageType_,
      includeSecondary_,
      includeRental_
    );

    if (!erc1155_) {
      for (uint256 i = 0; i < delegatedAddresses.length; ) {
        unchecked {
          balance_ += (
            IERC721(contractAddress_).balanceOf(delegatedAddresses[i])
          );

          i++;
        }
      }
    } else {
      for (uint256 i = 0; i < delegatedAddresses.length; ) {
        unchecked {
          balance_ += (
            IERC1155(contractAddress_).balanceOf(delegatedAddresses[i], id_)
          );

          i++;
        }
      }
    }

    return (balance_);
  }

  /**
   *
   *
   * @dev beneficiaryOf - The beneficiary of for a token, traversing all levels of the
   * register
   *
   * @param collection_ The contract we are checking beneficiaries on
   * @param tokenId_ The token Id we are querying
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return primaryBeneficiary_ The primary beneficiary - there can be only one
   * @return secondaryBeneficiaries_ An array of secondary beneficiaries i.e. thos
   * referenced on non-atomic secondary delegations
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
    )
  {
    address owner = IERC721(collection_).ownerOf(tokenId_);

    (
      primaryBeneficiary_,
      secondaryBeneficiaries_
    ) = _getBeneficiaryByTokenDelegation(
      owner,
      collection_,
      tokenId_,
      usageType_,
      includeSecondary_,
      includeRental_
    );

    // If the benficiary is still the token owner we now want to check if that
    // owner has a delegation in place for this usageType
    if (primaryBeneficiary_ == address(0)) {
      (
        primaryBeneficiary_,
        secondaryBeneficiaries_
      ) = _getBeneficiaryByGlobalOrCollectionDelegation(
        owner,
        collection_,
        usageType_,
        [includeSecondary_, includeRental_]
      );
    }

    if (primaryBeneficiary_ == address(0)) {
      primaryBeneficiary_ = owner;
    }

    return (primaryBeneficiary_, secondaryBeneficiaries_);
  }

  /**
   *
   *
   * @dev _getBeneficiaryByTokenDelegation - get the beneficiary for a token by
   * valid token delegations
   *
   * @param owner_ The owner of the token
   * @param collection_ The contract we are checking beneficiaries on
   * @param tokenId_ The token Id we are querying
   * @param usageType_ The usage type for the delegation
   * @param includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * @param includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return primaryBeneficiary_ The primary beneficiary - there can be only one
   * @return secondaryBeneficiaries_ An array of secondary beneficiaries i.e. thos
   * referenced on non-atomic secondary delegations
   *
   *
   */
  function _getBeneficiaryByTokenDelegation(
    address owner_,
    address collection_,
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    internal
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    )
  {
    EnumerableSet.AddressSet storage ownedTokenDelegations = _tokenToDelegation[
      _getTokenDelegationHash(owner_, collection_, tokenId_)
    ];

    // We have a local object with an enumerable set of delegation key hashes
    uint256 tokenDelegationCount = ownedTokenDelegations.length();
    uint256 actualCount;

    secondaryBeneficiaries_ = new address[](tokenDelegationCount);

    for (uint256 i = 0; i < tokenDelegationCount; i++) {
      DelegationRecord memory currentDelegation = _delegationRecord[
        ownedTokenDelegations.at(i)
      ];

      if (
        (!_delegationIsValid(
          DelegationCheckAddresses(currentDelegation.hot, owner_, collection_),
          DelegationCheckClasses(includeSecondary_, includeRental_, true),
          currentDelegation.controlInteger,
          usageType_,
          tokenId_,
          ValidityDates(currentDelegation.startDate, currentDelegation.endDate),
          ownedTokenDelegations.at(i)
        ) ||
          (_delegationRecord[ownedTokenDelegations.at(i)].status ==
            DelegationStatus.pending))
      ) {
        continue;
      }

      if (
        _delegationClass(currentDelegation.controlInteger) !=
        DelegationClass.secondary
      ) {
        primaryBeneficiary_ = currentDelegation.hot;
      } else {
        // Made it here. Add it:
        secondaryBeneficiaries_[actualCount] = currentDelegation.hot;

        unchecked {
          actualCount++;
        }
      }
    }

    if (tokenDelegationCount > actualCount) {
      assembly {
        let decrease := sub(tokenDelegationCount, actualCount)
        mstore(
          secondaryBeneficiaries_,
          sub(mload(secondaryBeneficiaries_), decrease)
        )
      }
    }

    return (primaryBeneficiary_, secondaryBeneficiaries_);
  }

  /**
   *
   *
   * @dev _getBeneficiaryByGlobalOrCollectionDelegation - get token Beneficiary by
   * colleciton or global delegation
   *
   * @param owner_ The owner of the token
   * @param collection_ The contract we are checking beneficiaries on
   * @param usageType_ The usage type for the delegation
   * @param inclusionParams_ Placed in an array to reduce local variable count. These are:
   * [0] includeSecondary_ If this is set to true the register will also check
   * secondary delegations (i.e. non-atomic delegations)
   * [1] includeRental_ If this is set to true the register will also check
   * rental delegations. Note that rental delegations ARE atomic.
   *
   * @return primaryBeneficiary_ The primary beneficiary - there can be only one
   * @return secondaryBeneficiaries_ An array of secondary beneficiaries i.e. thos
   * referenced on non-atomic secondary delegations
   *
   *
   */
  function _getBeneficiaryByGlobalOrCollectionDelegation(
    address owner_,
    address collection_,
    uint256 usageType_,
    bool[2] memory inclusionParams_
  )
    internal
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    )
  {
    EnumerableSet.AddressSet storage ownerDelegations = _coldToDelegation[
      _coldMappingKey(owner_)
    ];

    uint256 actualCount;

    secondaryBeneficiaries_ = new address[](ownerDelegations.length());

    for (uint256 i = 0; i < ownerDelegations.length(); i++) {
      DelegationRecord memory currentDelegation = _delegationRecord[
        ownerDelegations.at(i)
      ];

      address collectionToCheck = address(0);

      if (_collectionSpecific(currentDelegation.controlInteger)) {
        collectionToCheck = collection_;
      }

      if (
        !_delegationIsValid(
          DelegationCheckAddresses(
            currentDelegation.hot,
            owner_,
            collectionToCheck
          ),
          DelegationCheckClasses(
            inclusionParams_[0],
            inclusionParams_[1],
            false
          ),
          currentDelegation.controlInteger,
          usageType_,
          0,
          ValidityDates(currentDelegation.startDate, currentDelegation.endDate),
          ownerDelegations.at(i)
        ) ||
        // Check if the cold address has a collection specific delegation for this collection:
        // Only proceed if there ISN'T a collection specific delegation for this usage type:
        (!_collectionSpecific(currentDelegation.controlInteger) &&
          (
            _includesUsageTypeOrAll(
              usageType_,
              _delegationTypesForAddress[
                _getDelegationTypeHash(owner_, collection_, false, 0)
              ]
            )
          ))
      ) {
        continue;
      }

      if (
        _delegationClass(currentDelegation.controlInteger) !=
        DelegationClass.secondary
      ) {
        primaryBeneficiary_ = currentDelegation.hot;
      } else {
        // Made it here. Add it:
        secondaryBeneficiaries_[actualCount] = currentDelegation.hot;

        unchecked {
          actualCount++;
        }
      }
    }

    return (primaryBeneficiary_, secondaryBeneficiaries_);
  }

  /**
   *
   *
   * @dev delegationFromColdExists - check a cold delegation exists
   *
   * @param cold_ The cold address we are querying
   * @param delegationKey_ The specific address key for a delegation
   *
   * @return bool if this exists (true) or not (false)
   *
   *
   */
  function delegationFromColdExists(address cold_, address delegationKey_)
    public
    view
    returns (bool)
  {
    if (!_coldToDelegation[_coldMappingKey(cold_)].contains(delegationKey_)) {
      return (false);
    }

    return (true);
  }

  /**
   *
   *
   * @dev delegationFromHotExists - check a hot delegation exists
   *
   * @param hot_ The hot address we are querying
   * @param delegationKey_ The specific address key for a delegation
   *
   * @return bool if this exists (true) or not (false)
   *
   *
   */
  function delegationFromHotExists(address hot_, address delegationKey_)
    public
    view
    returns (bool)
  {
    if (!_hotToDelegation[_hotMappingKey(hot_)].contains(delegationKey_)) {
      return (false);
    }

    return (true);
  }

  /**
   *
   *
   * @dev getAllForHot - Get all delegations at a hot address, formatted nicely
   *
   * @param hot_ The hot address we are querying
   *
   * @return DelegationReport[] An array of delegation report objects providing
   * full details of all delegations for this hot address
   *
   *
   */
  function getAllForHot(address hot_)
    external
    view
    returns (DelegationReport[] memory)
  {
    EnumerableSet.AddressSet storage hotDelegations = _hotToDelegation[
      _hotMappingKey(hot_)
    ];

    uint256 delegationCount = hotDelegations.length();

    DelegationReport[] memory allForHot = new DelegationReport[](
      delegationCount
    );

    for (uint256 i = 0; i < delegationCount; ) {
      address delegationKey = hotDelegations.at(i);

      DelegationRecord memory currentDelegation = _delegationRecord[
        delegationKey
      ];

      allForHot[i] = _getAllReportLine(
        hot_,
        currentDelegation.cold,
        currentDelegation.controlInteger,
        delegationFromColdExists(currentDelegation.cold, delegationKey),
        currentDelegation.startDate,
        currentDelegation.endDate,
        delegationKey,
        currentDelegation.status
      );

      unchecked {
        i++;
      }
    }

    return (allForHot);
  }

  /**
   *
   *
   * @dev getAllForCold - Get all delegations at a cold address, formatted nicely
   *
   * @param cold_ The cold address we are querying
   *
   * @return DelegationReport[] An array of delegation report objects providing
   * full details of all delegations for this cold address
   *
   *
   */
  function getAllForCold(address cold_)
    external
    view
    returns (DelegationReport[] memory)
  {
    EnumerableSet.AddressSet storage coldDelegations = _coldToDelegation[
      _coldMappingKey(cold_)
    ];

    uint256 delegationCount = coldDelegations.length();

    DelegationReport[] memory allForCold = new DelegationReport[](
      delegationCount
    );

    for (uint256 i = 0; i < delegationCount; ) {
      address delegationKey = coldDelegations.at(i);

      DelegationRecord memory currentDelegation = _delegationRecord[
        delegationKey
      ];

      allForCold[i] = _getAllReportLine(
        currentDelegation.hot,
        cold_,
        currentDelegation.controlInteger,
        delegationFromHotExists(currentDelegation.hot, delegationKey),
        currentDelegation.startDate,
        currentDelegation.endDate,
        delegationKey,
        currentDelegation.status
      );

      unchecked {
        i++;
      }
    }

    return (allForCold);
  }

  /**
   *
   *
   * @dev _getAllReportLine - Get a line for the All report
   *
   * @param hot_ The hot address we are querying
   * @param cold_ The cold address we are querying
   * @param controlInteger_ The control integer for this record
   * @param bilaterallyValid_ If this entry has a delegation record from the
   * hot to the cold AND the cold to the hot. This may not be the case, as a result
   * of revoke all transactions
   * @param startDate_ The start date of the delegation
   * @param endDate_ The end date of the delegation
   * @param delegationKey_ The address key for this delegation
   * @param status_ The status of this delegation
   *
   * @return DelegationReport An object providing full details of this delegation
   *
   *
   */
  function _getAllReportLine(
    address hot_,
    address cold_,
    uint96 controlInteger_,
    bool bilaterallyValid_,
    uint40 startDate_,
    uint40 endDate_,
    address delegationKey_,
    DelegationStatus status_
  ) internal view returns (DelegationReport memory) {
    DelegationMetadata memory currentMetadata = delegationMetadata[
      delegationKey_
    ];

    return
      DelegationReport(
        hot_,
        cold_,
        _delegationScope(controlInteger_),
        _delegationClass(controlInteger_),
        _delegationTimeLimit(controlInteger_),
        currentMetadata.collection,
        currentMetadata.tokenId,
        startDate_,
        endDate_,
        !_hasDates(controlInteger_) || _datesAreValid(startDate_, endDate_),
        bilaterallyValid_,
        _delegationScope(controlInteger_) != DelegationScope.token ||
          IERC721(currentMetadata.collection).ownerOf(
            currentMetadata.tokenId
          ) ==
          cold_,
        _decodedUsageTypes(controlInteger_),
        delegationKey_,
        controlInteger_,
        currentMetadata.data,
        status_
      );
  }

  // ======================================================
  // MAKE DELEGATIONS
  // ======================================================

  /**
   *
   *
   * @dev makeDelegation - A direct call to setup a new proxy record
   *
   * @param hot_ The hot address we are querying
   * @param cold_ The cold address we are querying
   * @param targetAddresses_ An array of addresses to make delegations for. These
   * should be collection addresses, other contract addresses or address(0) for global
   * @param tokenId_ If this is a token level delegation this should be provided
   * @param tokenDelegation_ If this is a token delegation (true) or not (false)
   * @param usageTypes_ An array of usage types for this delegation
   * @param startDate_ The start date of the delegation
   * @param endDate_ The end date of the delegation
   * @param providerCode_ If this delegation has been introduced through a provider this
   * should hold their unique code
   * @param delegationClass_ The class of the delegation: 0 = primary, 1 = secondary,
   * 3 = rental
   * @param subDelegateKey_ Provide the subdelegate key is performing this delegation from a
   * valid subdelegate
   * @param data_ Additional data to include in the delegation e.g. a hyperlink or details
   * of an IP licensing agreement
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
  ) external payable {
    if (msg.value != _proxyRegisterFee) revert IncorrectProxyRegisterFee();

    Delegation memory newDelegation = Delegation(
      hot_,
      cold_,
      targetAddresses_,
      tokenId_,
      tokenDelegation_,
      usageTypes_,
      startDate_,
      endDate_,
      providerCode_,
      delegationClass_,
      subDelegateKey_,
      data_,
      DelegationStatus.live
    );

    _makeDelegation(newDelegation, _msgSender());
  }

  /**
   *
   *
   * @dev _makeDelegation - perform unified processing for making delegations
   *
   * @param newDelegation_ The new delegation object containing all details of the
   * delegation
   * @param caller_ The address that has made this call
   *
   *
   */
  function _makeDelegation(Delegation memory newDelegation_, address caller_)
    internal
  {
    for (uint256 i = 0; i < newDelegation_.targetAddresses.length; ) {
      _initialValidation(
        newDelegation_.hot,
        newDelegation_.cold,
        newDelegation_.subDelegateKey,
        caller_
      );

      uint96 controlInteger = _constructAndCheckControlInteger(
        newDelegation_.cold,
        newDelegation_.targetAddresses[i],
        newDelegation_.tokenId,
        newDelegation_.tokenDelegation,
        newDelegation_.usageTypes,
        newDelegation_.startDate,
        newDelegation_.endDate,
        newDelegation_.delegationClass
      );

      // Create the delegation key:
      address delegationKey = getDelegationKey(
        newDelegation_.hot,
        newDelegation_.cold,
        newDelegation_.targetAddresses[i],
        newDelegation_.tokenId,
        newDelegation_.tokenDelegation,
        controlInteger,
        newDelegation_.startDate,
        newDelegation_.endDate
      );

      if (newDelegation_.tokenDelegation) {
        // Map the token to the delegation so that it can retrieve and check the details
        // later. Note that token delegations are mapped in a different way to global
        // and collection delegations.

        // Mapping is the cold wallet (current owner), with the contract and token Id

        _tokenToDelegation[
          _getTokenDelegationHash(
            newDelegation_.cold,
            newDelegation_.targetAddresses[i],
            newDelegation_.tokenId
          )
        ].add(delegationKey);
      }

      if (
        newDelegation_.targetAddresses[i] != address(0) ||
        newDelegation_.data.length != 0
      ) {
        delegationMetadata[delegationKey] = DelegationMetadata(
          newDelegation_.targetAddresses[i],
          newDelegation_.tokenId,
          newDelegation_.data
        );
      }

      if (newDelegation_.status == DelegationStatus.pending) {
        pendingPayments[newDelegation_.cold].push(delegationKey);
      }

      // Save the delegation for the hot:
      _hotToDelegation[_hotMappingKey(newDelegation_.hot)].add(delegationKey);

      // Save the delegation for the cold:
      _coldToDelegation[_coldMappingKey(newDelegation_.cold)].add(
        delegationKey
      );

      _delegationRecord[delegationKey] = DelegationRecord(
        newDelegation_.hot,
        uint96(controlInteger),
        newDelegation_.cold,
        newDelegation_.startDate,
        newDelegation_.endDate,
        newDelegation_.status
      );

      _emitDelegationMade(newDelegation_, i);

      unchecked {
        i++;
      }
    }

    if (address(rewardToken) != address(0)) {
      if (newDelegation_.status == DelegationStatus.live) {
        rewardToken.emitToken(
          _msgSender(),
          rewardRate * newDelegation_.targetAddresses.length
        );
      }
    }
  }

  /**
   *
   *
   * @dev _emitDelegationMade - Emit the event for a new delegation
   *
   * @param newDelegation_ The new delegation object containing all details of the
   * delegation
   * @param index_ The contract / collection address from the addresses array that
   * has been delegated
   *
   *
   */
  function _emitDelegationMade(Delegation memory newDelegation_, uint256 index_)
    internal
  {
    emit DelegationMade(
      newDelegation_.hot,
      newDelegation_.cold,
      newDelegation_.targetAddresses[index_],
      newDelegation_.tokenId,
      newDelegation_.tokenDelegation,
      newDelegation_.usageTypes,
      newDelegation_.startDate,
      newDelegation_.endDate,
      newDelegation_.providerCode,
      newDelegation_.delegationClass,
      newDelegation_.subDelegateKey,
      newDelegation_.data,
      newDelegation_.status
    );
  }

  /**
   *
   *
   * @dev _initialValidation - Initial validation of a make delegation call
   *
   * @param hot_ The hot address for the delegation
   * @param cold_ The cold address for the delegation
   * @param subDelegateKey_ If this is a subdelegate called delegation this will
   * include the subdelegate key
   * @param caller_ The caller on this transaction
   *
   *
   */
  function _initialValidation(
    address hot_,
    address cold_,
    uint96 subDelegateKey_,
    address caller_
  ) internal view {
    if (_hotAddressIsLocked(hot_, cold_)) {
      revert HotAddressIsLockedAndCannotBeDelegatedTo();
    }

    _delegatedAuthorityCheck(caller_, cold_, subDelegateKey_);
  }

  /**
   *
   *
   * @dev _getTokenDelegationHash - create a token delegation hash
   *
   * @param cold_ The cold address for the delegation
   * @param collection_ The collection for this delegation hadsh (note is
   * address(0) for global delegations)
   * @param tokenId_ The token Id for the hash
   *
   * @return bytes32 Hash of the arguments
   *
   *
   */
  function _getTokenDelegationHash(
    address cold_,
    address collection_,
    uint256 tokenId_
  ) internal view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          cold_,
          _coldWalletTranche[cold_],
          collection_,
          tokenId_
        )
      );
  }

  /**
   *
   *
   * @dev _constructAndCheckControlInteger - check for overlapping delegations
   * and build the control integer for storage
   *
   * @param cold_ The cold address for the delegation
   * @param collection_ The collection for this delegation hadsh (note is
   * address(0) for global delegations
   * @param tokenId_ The token Id for this delegation (if relevant)
   * @param tokenDelegation_ If this is a token delegation (true) or not (false)
   * @param startDate_ The start date of the delegation
   * @param endDate_ The end date of the delegation
   * @param delegationClass_ The class of the delegation: 0 = primary, 1 = secondary,
   * 3 = rental
   *
   *
   */
  function _constructAndCheckControlInteger(
    address cold_,
    address collection_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint8[] memory usageTypes_,
    uint40 startDate_,
    uint40 endDate_,
    DelegationClass delegationClass_ //0 = primary, 1 = secondary, 2 = rental
  ) internal returns (uint96 controlInteger_) {
    uint256 usageTypesInteger;

    unchecked {
      // Is this global, collection or token based?
      if (collection_ != address(0)) {
        if (tokenDelegation_) {
          // If a cold is delegating a specific token it HAS to own it
          if (IERC721(collection_).ownerOf(tokenId_) != cold_) {
            revert CannotDelegatedATokenYouDontOwn();
          }
          controlInteger_ += TOKEN_DELEGATION;
        } else {
          controlInteger_ += COLLECTION_DELEGATION;
        }
      }

      // Is this a secondary delegation?
      if (delegationClass_ == DelegationClass.secondary) {
        controlInteger_ += SECONDARY_DELEGATION;
      }

      // Is this a rental delegation?
      if (delegationClass_ == DelegationClass.rental) {
        controlInteger_ += RENTAL_DELEGATION;
      }

      // Is this eternal or time based?
      if (startDate_ + endDate_ != 0) {
        controlInteger_ += TIME_BASED_DELEGATION;
      }
    }

    // Construct control integers, checking that the cold address hasn't already delegated
    // these usage codes to another address.

    for (uint256 i = 0; i < usageTypes_.length; ) {
      // Check for duplication IF this is a primary delegation:

      if (
        delegationClass_ != DelegationClass.secondary &&
        _hasExistingDelegation(
          cold_,
          collection_,
          tokenDelegation_,
          tokenId_,
          usageTypes_[i]
        )
      ) {
        // Uh oh, we have already delegated this type for this:
        revert UsageTypeAlreadyDelegated(usageTypes_[i]);
      }

      unchecked {
        if (usageTypes_[i] == 1) {
          usageTypesInteger += 1;
        } else {
          usageTypesInteger += 1 * (10**(usageTypes_[i] - 1));
        }

        i++;
      }
    }

    // All good? OK, record that this delegation is using these usage types by incrementing
    // the delegation type hash IF this is not a secondary delegation
    unchecked {
      if (delegationClass_ != DelegationClass.secondary) {
        _delegationTypesForAddress[
          _getDelegationTypeHash(cold_, collection_, tokenDelegation_, tokenId_)
        ] += usageTypesInteger;
      }

      controlInteger_ += uint96(usageTypesInteger);
    }

    return (controlInteger_);
  }

  /**
   *
   *
   * @dev _delegationIsValid - Return if a delegation is valid or not
   *
   * @param addresses_ The addresses to be checked (hot, cold and collection)
   * @param classes_ What classes to check (0 = primary, 1 = secondary, 3 = rental)
   * @param controlInteger_ The conrol integer for this delegation
   * @param usageType_ The usage type being checked
   * @param tokenId_ The delegated token Id, if relevant
   * @param dates_ The start and end date of the delegation
   * @param receivedDelegationKey_ A received delegation key to check, if provided
   *
   * @return valid_ If this is valid (true) or not (false)
   *
   *
   */
  function _delegationIsValid(
    DelegationCheckAddresses memory addresses_,
    DelegationCheckClasses memory classes_,
    uint96 controlInteger_,
    uint256 usageType_,
    uint256 tokenId_,
    ValidityDates memory dates_,
    address receivedDelegationKey_
  ) internal view returns (bool valid_) {
    // If this is a secondary delegation only proceed if we have been
    // passed that argument
    if (
      (!classes_.secondary &&
        _delegationClass(controlInteger_) == DelegationClass.secondary) ||
      (!classes_.rental &&
        _delegationClass(controlInteger_) == DelegationClass.rental) ||
      !_includesUsageTypeOrAll(usageType_, controlInteger_)
    ) {
      return (false);
    }

    // Create the delegation key:
    address delegationKey = getDelegationKey(
      addresses_.hot,
      addresses_.cold,
      addresses_.targetCollection,
      tokenId_,
      classes_.token,
      controlInteger_,
      dates_.start,
      dates_.end
    );

    if (
      (!delegationFromColdExists(addresses_.cold, delegationKey)) ||
      (!delegationFromHotExists(addresses_.hot, delegationKey)) ||
      (_delegationRecord[delegationKey].status == DelegationStatus.pending) ||
      (_collectionSpecific(controlInteger_) &&
        (delegationMetadata[delegationKey].collection !=
          addresses_.targetCollection)) ||
      (_hasDates(controlInteger_) &&
        !_datesAreValid(dates_.start, dates_.end)) ||
      (receivedDelegationKey_ != address(0) &&
        receivedDelegationKey_ != delegationKey)
    ) {
      return (false);
    }

    // Made it here. It's valid:
    return (true);
  }

  /**
   *
   *
   * @dev _decodedUsageTypes - decode a control integer into a uint8 array of usage types
   *
   * @param controlInteger_ The conrol integer for this delegation
   *
   * @return usageTypes_ A uint8 array of usage types
   *
   *
   */
  function _decodedUsageTypes(uint256 controlInteger_)
    internal
    pure
    returns (bool[NUMBER_OF_USAGE_TYPES] memory usageTypes_)
  {
    for (uint256 i = 0; i < NUMBER_OF_USAGE_TYPES; ) {
      usageTypes_[i] = _includesUsageType(i + 1, controlInteger_);
      unchecked {
        i++;
      }
    }

    return (usageTypes_);
  }

  /**
   *
   *
   * @dev _hotMappingKey - Hashes the hot address with the current tranch
   *
   * @param hot_ The hot address
   *
   * @return bytes32 A hash of the hot with the current tranche for that hot
   *
   *
   */
  function _hotMappingKey(address hot_) internal view returns (bytes32) {
    return (keccak256(abi.encodePacked(hot_, _hotWalletTranche[hot_])));
  }

  /**
   *
   *
   * @dev _coldMappingKey - Hashes the cold address with the current tranch
   *
   * @param cold_ The cold address
   *
   * @return bytes32 A hash of the cold with the current tranche for that cold
   *
   *
   */
  function _coldMappingKey(address cold_) internal view returns (bytes32) {
    return (keccak256(abi.encodePacked(cold_, _coldWalletTranche[cold_])));
  }

  /**
   *
   *
   * @dev _collectionSpecific - return if delegation is collection specific
   *
   * @param controlInteger_ The control integer being queried
   *
   * @return bool If this is collection specific (or not)
   *
   *
   */
  function _collectionSpecific(uint256 controlInteger_)
    internal
    pure
    returns (bool)
  {
    return (_delegationScope(controlInteger_) == DelegationScope.collection);
  }

  /**
   *
   *
   * @dev _hasDates - return if delegation is date limited
   *
   * @param controlInteger_ The control integer being queried
   *
   * @return bool If this delegation has dates (or not)
   *
   *
   */
  function _hasDates(uint256 controlInteger_) internal pure returns (bool) {
    return (_delegationTimeLimit(controlInteger_) ==
      DelegationTimeLimit.limited);
  }

  /**
   *
   *
   * @dev _delegationClass - returns the type of delegation (primary, secondary or rental)
   *
   * @param controlInteger_ The control integer being queried
   *
   * @return DelegationClass The delegation class (primary, secondary, rental)
   *
   *
   */
  function _delegationClass(uint256 controlInteger_)
    internal
    pure
    returns (DelegationClass)
  {
    if (_controlIntegerValue(26, controlInteger_) == 0) {
      return (DelegationClass.primary);
    }
    if (_controlIntegerValue(26, controlInteger_) == 1) {
      return (DelegationClass.secondary);
    } else {
      return (DelegationClass.rental);
    }
  }

  /**
   *
   *
   * @dev _coldOwnerOrSubDelegate - returns if the passed address is the cold or subdelegate
   * for the cold
   *
   * @param caller_ The calling address
   * @param cold_ The cold address
   * @param controlInteger_ The control integer being queried
   *
   * @return bool If the caller is a subdelegate for this cold (true), or not (false)
   *
   *
   */
  function _coldOwnerOrSubDelegate(
    address caller_,
    address cold_,
    uint96 controlInteger_
  ) internal view returns (bool) {
    if (cold_ == caller_) return (true);

    return (
      _delegationIsValid(
        DelegationCheckAddresses(caller_, cold_, address(0)),
        DelegationCheckClasses(true, true, false),
        controlInteger_,
        SUB_DELEGATION,
        0,
        ValidityDates(0, 0),
        address(0)
      )
    );
  }

  /**
   *
   *
   * @dev _delegationTimeLimit - returns the type of time limit (eternal, limited))
   *
   * @param controlInteger_ The control integer being queried
   *
   * @return DelegationTimeLimit The delegation time limit (eternal or timelimted)
   *
   *
   */
  function _delegationTimeLimit(uint256 controlInteger_)
    internal
    pure
    returns (DelegationTimeLimit)
  {
    if (_controlIntegerValue(27, controlInteger_) == 0) {
      return (DelegationTimeLimit.eternal);
    } else {
      return (DelegationTimeLimit.limited);
    }
  }

  /**
   *
   *
   * @dev _delegationScope - returns the scope of the delegation
   * (0 = global, 1 = collection, 2 = token)
   *
   * @param controlInteger_ The control integer being queried
   *
   * @return DelegationScope The scope of the delegation (0 = global,
   * 1 = collection, 2 = token)
   *
   *
   */
  function _delegationScope(uint256 controlInteger_)
    internal
    pure
    returns (DelegationScope)
  {
    uint256 scope = _controlIntegerValue(28, controlInteger_);

    if (scope == 0) {
      return (DelegationScope.global);
    }
    if (scope == 1) {
      return (DelegationScope.collection);
    } else {
      return (DelegationScope.token);
    }
  }

  /**
   *
   *
   * @dev _datesAreValid - check if the passed dates are valid
   *
   * @param startDate_ The start date of the delegation
   * @param endDate_ The end date of the delegation
   *
   * @return bool If these dates are valid
   *
   *
   */
  function _datesAreValid(uint256 startDate_, uint256 endDate_)
    internal
    view
    returns (bool)
  {
    return (startDate_ < block.timestamp && endDate_ > block.timestamp);
  }

  /**
   *
   *
   * @dev _includesUsageType - check if this includes a given usage type
   *
   * @param usageType_ The usage type we are interested in
   * @param controlInteger_ The control integer being queried
   *
   * @return bool If the control integer includes the usage type
   *
   *
   */
  function _includesUsageType(uint256 usageType_, uint256 controlInteger_)
    internal
    pure
    returns (bool)
  {
    return (_controlIntegerIsTrue(usageType_, controlInteger_));
  }

  /**
   *
   *
   * @dev _includesUsageTypeOrAll - check if this includes a given usage type or is for all
   *
   * @param usageType_ The usage type we are interested in
   * @param controlInteger_ The control integer being queried
   *
   * @return bool If the control integer includes the usage type OR all
   *
   *
   */
  function _includesUsageTypeOrAll(uint256 usageType_, uint256 controlInteger_)
    internal
    pure
    returns (bool)
  {
    // Sub delegation type ALWAYS has to match, it is not included in 'all'
    if (
      usageType_ != SUB_DELEGATION &&
      _controlIntegerIsTrue(ALL_DELEGATION, controlInteger_)
    ) {
      return (true);
    } else {
      return (_controlIntegerIsTrue(usageType_, controlInteger_));
    }
  }

  /**
   *
   *
   * @dev getDelegationKey - get the link hash to the delegation metadata
   *
   * @param hot_ The hot address we are querying
   * @param cold_ The cold address we are querying
   * @param targetAddress_ The collection or contract for the scope of the delegation
   * @param tokenId_ The token ID for token delegations
   * @param tokenDelegation_ A bool to indicate this is a token delegation
   * @param controlInteger_ The control integer for this record
   * @param startDate_ The start date of the delegation
   * @param endDate_ The end date of the delegation
   *
   * @return address The delegation key
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
  ) public pure returns (address) {
    return (
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                hot_,
                cold_,
                targetAddress_,
                tokenId_,
                tokenDelegation_,
                controlInteger_,
                startDate_,
                endDate_
              )
            )
          )
        )
      )
    );
  }

  /**
   *
   *
   * @dev _getDelegationTypeHash - get the hash that points to what delegations
   * this cold has already made, either for a token, targetAddress (collection),
   * or for all (using address(0))
   *
   * @param cold_ The cold address we are querying
   * @param collection_ The collection or contract for the scope of the delegation
   * @param tokenBased_ A bool to indicate this is a token delegation
   * @param tokenId_ The token ID for token delegations
   *
   * @return bytes32 The delegation type hash
   *
   *
   */
  function _getDelegationTypeHash(
    address cold_,
    address collection_,
    bool tokenBased_,
    uint256 tokenId_
  ) internal view returns (bytes32) {
    return (
      keccak256(
        abi.encodePacked(
          cold_,
          collection_,
          tokenBased_,
          tokenId_,
          _coldWalletTranche[cold_]
        )
      )
    );
  }

  /**
   *
   * @dev _controlIntegerIsTrue - extract a position from the control integer and
   * confirm if true
   *
   * @param position_ The position in the control integer for this item
   * @param typeInteger_ The type we are looking for
   *
   * @return bool If the control integer is set to true
   *
   *
   */
  function _controlIntegerIsTrue(uint256 position_, uint256 typeInteger_)
    internal
    pure
    returns (bool)
  {
    return (_controlIntegerValue(position_, typeInteger_) == 1);
  }

  /**
   *
   *
   * @dev _controlIntegerValue - the value at a position in the control integer
   *
   * @param position_ The position in the control integer for this item
   * @param typeInteger_ The type we are looking for
   *
   * @return uint256 The value at the requested position
   *
   *
   */
  function _controlIntegerValue(uint256 position_, uint256 typeInteger_)
    internal
    pure
    returns (uint256)
  {
    uint256 exponent = (10**(position_));
    uint256 divisor;
    if (position_ == 1) {
      divisor = 1;
    } else {
      divisor = (10**((position_ - 1)));
    }

    return ((typeInteger_ % exponent) / divisor);
  }

  // ======================================================
  // ADDRESS LOCKING
  // ======================================================

  /**
   *
   *
   * @dev getHotAddressLockDetails - get address lock details, both dates
   * and any bypass addresses
   *
   * @param hot_ The hot address being queried
   *
   * @return LockDetails The start and end date of any lock
   * @return address[] A list of bypass addresses
   *
   *
   */
  function getHotAddressLockDetails(address hot_)
    external
    view
    returns (LockDetails memory, address[] memory)
  {
    return (_addressLockDetails[hot_], _lockBypassList[hot_].values());
  }

  /**
   *
   *
   * @dev unlockAddressUntilTime - Unlock for new delegations from cold
   * addresses until a predetermined time in the future. E.g. unlock for
   * 10 minutes while you perform delegations.
   *
   * @param lockAtTime_ The time you wish to re-lock for new delegations
   *
   *
   */
  function unlockAddressUntilTime(uint40 lockAtTime_) external {
    _setLockDetails(_msgSender(), lockAtTime_, type(uint40).max);
  }

  /**
   *
   *
   * @dev lockAddressUntilDate - Lock address until a future date when it
   * will unlock
   *
   * @param unlockDate_ The time you wish to unlock for new delegations
   *
   *
   */
  function lockAddressUntilDate(uint40 unlockDate_) external {
    _setLockDetails(_msgSender(), uint40(block.timestamp), unlockDate_);
  }

  /**
   *
   *
   * @dev lockAddress - Lock address until manually unlocked
   *
   *
   */
  function lockAddress() external {
    _setLockDetails(_msgSender(), uint40(block.timestamp), type(uint40).max);
  }

  /**
   *
   *
   * @dev unlockAddress - Unlock address for new delegations from cold addresses
   *
   *
   */
  function unlockAddress() external {
    delete _addressLockDetails[_msgSender()];
  }

  /**
   *
   *
   * @dev addLockBypassAddress - add an entry to the lock bypass list
   *
   * @param bypassAddress_ The address to add to your bypass list
   *
   *
   */
  function addLockBypassAddress(address bypassAddress_) external {
    _lockBypassList[_msgSender()].add(bypassAddress_);
  }

  /**
   *
   *
   * @dev removeLockBypassAddress - remove an entry from the lock bypass list
   *
   * @param bypassAddress_ The address to remove from your bypass list
   *
   *
   */
  function removeLockBypassAddress(address bypassAddress_) external {
    _lockBypassList[_msgSender()].remove(bypassAddress_);
  }

  /**
   *
   *
   * @dev _hotAddressIsLocked - returns if this hot address is locked for this cold
   *
   * @param hot_ The hot address to be delegated to
   * @param cold_ The cold address to the delegated from
   *
   * @return bool If this hot is locked for calls from this cold
   *
   *
   */
  function _hotAddressIsLocked(address hot_, address cold_)
    internal
    view
    returns (bool)
  {
    // Get lock details:
    LockDetails memory lock = _addressLockDetails[hot_];

    if (block.timestamp > lock.lockEnd || block.timestamp < lock.lockStart) {
      // No lock
      return (false);
    }

    // Lock is in force. See if this address is on the bypass list:
    if (_lockBypassList[hot_].contains(cold_)) {
      // Cold address is on the bypass list:
      return (false);
    }

    // Made it here? Must be locked:
    return (true);
  }

  /**
   *
   *
   * @dev _setLockDetails - Set the lock details the user has provided
   *
   * @param callingAddress_ The calling address to lock
   * @param lockAt_ The start of the lock
   * @param unLockAt_ The end of the lock
   *
   *
   */
  function _setLockDetails(
    address callingAddress_,
    uint40 lockAt_,
    uint40 unLockAt_
  ) internal {
    _addressLockDetails[callingAddress_] = LockDetails(lockAt_, unLockAt_);
  }

  // ======================================================
  // REVOKE
  // ======================================================

  /**
   *
   *
   * @dev revokeRecord - Revoking a single record with Key
   *
   * @param delegationKey_ The delegation key of the delegation you are
   * revoking
   * @param subDelegateKey_ The subdelegate key for this subdelegate if we
   * are performing a subdelegate action
   *
   *
   */
  function revokeRecord(address delegationKey_, uint96 subDelegateKey_)
    external
  {
    _revokeRecord(_msgSender(), delegationKey_, subDelegateKey_);
  }

  /**
   *
   *
   * @dev revokeRecordOfGlobalScopeForAllUsages - Revoke a delegation between
   * two parties for global scope and all usages
   *
   * @param participant2_ The second participant on a delegation (can be hot or
   * cold, the caller must be the other participant)
   *
   *
   */
  function revokeRecordOfGlobalScopeForAllUsages(address participant2_)
    external
  {
    _revokeRecordOfGlobalScopeForAllUsages(_msgSender(), participant2_);
  }

  /**
   *
   *
   * @dev _revokeRecordOfGlobalScopeForAllUsages: Revoking a global all usages
   *
   * @param participant1_ The first participant on a delegation (can be hot or
   * cold, participant 2 must be the other participant)
   * @param participant2_ The second participant on a delegation (can be hot or
   * cold, participant 1 must be the other participant)
   *
   *
   */
  function _revokeRecordOfGlobalScopeForAllUsages(
    address participant1_,
    address participant2_
  ) internal {
    if (_generateKeyAndRevoke(participant1_, participant2_)) {
      return;
    }

    if (_generateKeyAndRevoke(participant2_, participant1_)) {
      return;
    }

    revert InvalidDelegation();
  }

  /**
   *
   *
   * @dev _generateKeyAndRevoke - Generate a delegation key and perform
   * a revoke
   *
   * @param hot_ The hot address on the delegation
   * @param cold_ The cold address on the delegation
   *
   *
   */
  function _generateKeyAndRevoke(address hot_, address cold_)
    internal
    returns (bool)
  {
    address delegationKey = getDelegationKey(
      hot_,
      cold_,
      address(0),
      0,
      false,
      1,
      0,
      0
    );

    DelegationRecord memory currentDelegation = _delegationRecord[
      delegationKey
    ];

    if (currentDelegation.hot != address(0)) {
      _revokeRecord(hot_, delegationKey, 0);
      return (true);
    }

    return (false);
  }

  /**
   *
   *
   * @dev _delegatedAuthorityCheck: check for a subdelegate
   *
   * @param caller_ The calling address
   * @param cold_ The cold address on the delegation
   * @param subDelegateKey_ The subdelegate key
   *
   *
   */
  function _delegatedAuthorityCheck(
    address caller_,
    address cold_,
    uint96 subDelegateKey_
  ) internal view {
    if (!_coldOwnerOrSubDelegate(caller_, cold_, subDelegateKey_)) {
      // This isn't the cold address calling OR a subdelegate passing in their subdelegate key:
      revert OnlyParticipantOrAuthorisedSubDelegate();
    }
  }

  /**
   *
   *
   * @dev _revokeRecord - Revoke a delegation record
   *
   * @param caller_ The calling address
   * @param delegationKey_ The key for this delegation
   * @param subDelegateKey_ The subdelegate key
   *
   *
   */
  function _revokeRecord(
    address caller_,
    address delegationKey_,
    uint96 subDelegateKey_
  ) internal {
    // Cache the delegation from cold details:
    DelegationRecord memory currentDelegation = _delegationRecord[
      delegationKey_
    ];

    if (caller_ != currentDelegation.hot) {
      _delegatedAuthorityCheck(
        caller_,
        currentDelegation.cold,
        subDelegateKey_
      );
    }

    if (
      _delegationScope(currentDelegation.controlInteger) ==
      DelegationScope.token
    ) {
      DelegationMetadata memory currentMetadata = delegationMetadata[
        delegationKey_
      ];

      bytes32 tokenMappingKey = _getTokenDelegationHash(
        currentDelegation.cold,
        currentMetadata.collection,
        currentMetadata.tokenId
      );

      if (!_tokenToDelegation[tokenMappingKey].contains(delegationKey_)) {
        revert InvalidDelegation();
      }

      if (
        _tokenToDelegation[tokenMappingKey].remove(delegationKey_) &&
        _delegationClass(currentDelegation.controlInteger) !=
        DelegationClass.secondary
      ) {
        _decrementUsageTypes(
          currentDelegation.cold,
          currentMetadata.collection,
          true,
          currentMetadata.tokenId,
          currentDelegation.controlInteger
        );
      }
    }

    // Remove the hot mapping:
    _hotToDelegation[_hotMappingKey(currentDelegation.hot)].remove(
      delegationKey_
    );

    // Adjust the usageTypes record for this cold address IF we removed a record
    // and this isn't a secondary or token delegation
    if (
      _coldToDelegation[_coldMappingKey(currentDelegation.cold)].remove(
        delegationKey_
      ) &&
      _delegationClass(currentDelegation.controlInteger) !=
      DelegationClass.secondary &&
      _delegationScope(currentDelegation.controlInteger) !=
      DelegationScope.token
    ) {
      address collection;

      if (_collectionSpecific(currentDelegation.controlInteger)) {
        collection = delegationMetadata[delegationKey_].collection;
      }

      _decrementUsageTypes(
        currentDelegation.cold,
        collection,
        false,
        0,
        currentDelegation.controlInteger
      );
    }

    // Clear the delegation record:
    delete _delegationRecord[delegationKey_];
    // Clear the metadata record:
    delete delegationMetadata[delegationKey_];

    emit DelegationRevoked(
      currentDelegation.hot,
      currentDelegation.cold,
      delegationKey_
    );
  }

  /**
   *
   *
   * @dev _decrementUsageTypes - Decrease usage types at this hash
   *
   * @param cold_ The ccoldalling address
   * @param collection_ The collection for this hash (address(0) for global)
   * @param isTokenDelegation_ Bool to indicate this is a token delegation
   * @param tokenId_ Token Id if this is a token delegation
   * @param controlInteger_ The control integer for this delegation
   *
   *
   */
  function _decrementUsageTypes(
    address cold_,
    address collection_,
    bool isTokenDelegation_,
    uint256 tokenId_,
    uint96 controlInteger_
  ) internal {
    // Create the delegation types hash for this address, collection and token:
    bytes32 delegationTypeHash = _getDelegationTypeHash(
      cold_,
      collection_,
      isTokenDelegation_,
      tokenId_
    );

    _delegationTypesForAddress[delegationTypeHash] -= (controlInteger_ %
      (10**(LENGTH_OF_CONTROL_INTEGER - NUMBER_OF_USAGE_TYPES)));
  }

  /**
   *
   *
   * @dev revokeAllForCold: Cold calls and revokes ALL
   *
   * @param cold_ The ccoldalling address
   * @param subDelegateKey_ The subdelegate key
   *
   *
   */
  function revokeAllForCold(address cold_, uint96 subDelegateKey_) external {
    _delegatedAuthorityCheck(_msgSender(), cold_, subDelegateKey_);

    // As this clears the entire authority model it is not a suitable option
    // for this contract's delegations
    if (cold_ == address(this)) {
      revert CannotRevokeAllForRegisterAdminHierarchy();
    }

    // This simply updates the cold wallet tranche ID, so all existing
    // delegations will become invalid
    _revokeAllForCold(_msgSender());
  }

  /**
   *
   *
   * @dev _revokeAllForCold - Perform the revoke all for a cold address
   *
   * @param cold_ The cold address
   *
   *
   */
  function _revokeAllForCold(address cold_) internal {
    // This simply updates the cold wallet tranche ID, so all existing
    // delegations will become invalid
    unchecked {
      _coldWalletTranche[cold_] += 1;
    }
    emit AllDelegationsRevokedForCold(cold_);
  }

  /**
   *
   *
   * @dev revokeAllForHot: Hot calls and revokes ALL
   *
   *
   */
  function revokeAllForHot() external {
    // This simply updates the hot wallet tranche ID, so all existing
    // delegations will become invalid
    _revokeAllForHot(_msgSender());
  }

  /**
   *
   *
   * @dev _revokeAllForHot - Perform the revoke all for a cold address
   *
   * @param hot_ The hot address
   *
   *
   */
  function _revokeAllForHot(address hot_) internal {
    // This simply updates the hot wallet tranche ID, so all existing
    // delegations will become invalid
    unchecked {
      _hotWalletTranche[hot_] += 1;
    }
    emit AllDelegationsRevokedForHot(hot_);
  }

  /**
   *
   *
   * @dev deleteExpired: ANYONE can delete expired records
   *
   * @param delegationKey_ The delegation key for the item being removed
   *
   *
   */
  function deleteExpired(address delegationKey_) external {
    DelegationRecord memory currentRecord = _delegationRecord[delegationKey_];

    if (currentRecord.hot == address(0)) {
      revert InvalidDelegation();
    }

    // Only proceed if dates are INVALID:
    if (
      !_hasDates(currentRecord.controlInteger) ||
      _datesAreValid(currentRecord.startDate, currentRecord.endDate)
    ) {
      revert CannotDeleteValidDelegation();
    }

    // Remove through a call to revokeRecord:
    _revokeRecord(currentRecord.hot, delegationKey_, 0);
  }

  // ======================================================
  // EPSAPI
  // ======================================================

  /**
   *
   *
   * @dev tokenAPICall: receive an EPSAPI call
      MAKE_PRIMARY_DELEGATION = 1;
      REVOKE = 2;
      REVOKE_ALL_FOR_HOT = 3;
      REVOKE_ALL_FOR_COLD = 4;
      LOCK_HOT = 5;
      UNLOCK_HOT = 6;
      MAKE_SECONDARY_DELEGATION = 7;
      MAKE_30_DAY_PRIMARY_DELEGATION = 8;
      MAKE_90_DAY_PRIMARY_DELEGATION = 9;
   *
   * @param from_ The "sender" of API token
   * @param to_ The "receiver" of API token
   * @param amount_ The amount of API token, which will be broken down
   * into an address and a uin96 of instruction data
   *
   */

  // The amount and to address tell us about the delegation, and is structured as follows:
  // * To address is the counterparty for delegations and revokes, where applicable
  // * Amount converted as follows:
  // <address: if present the collection being delegated, otherwise global> <98765432129876543211987654321>  29 integers per uint96
  // The integer information maps as follows
  // 98765432129876543211987654321
  // ^-----------------------^|^-^
  //    | 25 Usage types      | | The provider code
  //                          |
  //                          | The txn code

  function _tokenAPICall(
    address from_,
    address to_,
    uint256 amount_
  ) internal {
    (address targetAddress, uint96 dataInteger) = _decodeDelegation(
      bytes32(amount_)
    );

    uint256 actionCode = (dataInteger / 10**3) % 10;

    if (actionCode == MAKE_PRIMARY_DELEGATION) {
      _apiDelegation(
        to_,
        from_,
        targetAddress,
        dataInteger,
        DelegationClass.primary,
        0
      );

      return;
    }

    if (actionCode == REVOKE) {
      if (targetAddress == address(0)) {
        // Revoke with global and all usages
        _revokeRecordOfGlobalScopeForAllUsages(from_, to_);
      } else {
        _revokeRecord(from_, targetAddress, 0);
      }

      return;
    }

    if (actionCode == REVOKE_ALL_FOR_HOT) {
      _revokeAllForHot(from_);

      return;
    }

    if (actionCode == REVOKE_ALL_FOR_COLD) {
      _revokeAllForCold(from_);

      return;
    }

    if (actionCode == LOCK_HOT) {
      _setLockDetails(from_, uint40(block.timestamp), type(uint40).max);

      return;
    }

    if (actionCode == UNLOCK_HOT) {
      delete _addressLockDetails[from_];

      return;
    }

    if (actionCode == MAKE_SECONDARY_DELEGATION) {
      _apiDelegation(
        to_,
        from_,
        targetAddress,
        dataInteger,
        DelegationClass.secondary,
        0
      );

      return;
    }

    if (actionCode == MAKE_30_DAY_PRIMARY_DELEGATION) {
      _apiDelegation(
        to_,
        from_,
        targetAddress,
        dataInteger,
        DelegationClass.primary,
        uint40(block.timestamp + 30 * 1 days)
      );

      return;
    }

    if (actionCode == MAKE_90_DAY_PRIMARY_DELEGATION) {
      _apiDelegation(
        to_,
        from_,
        targetAddress,
        dataInteger,
        DelegationClass.primary,
        uint40(block.timestamp + 90 * 1 days)
      );

      return;
    }

    revert UnrecognisedEPSAPIAmount();
  }

  /**
   *
   *
   * @dev _apiDelegation - process API introduced delegation
   *
   * @param hot_ The hot address
   * @param cold_ The cold address
   * @param targetAddress_ The collection from the API payload
   * @param dataInteger_ The data integer from the API payload
   * @param class_ The class of this delegation (0 primary, 1 secondary)
   * @param endDate_ The end date of this delegation
   *
   *
   */
  function _apiDelegation(
    address hot_,
    address cold_,
    address targetAddress_,
    uint256 dataInteger_,
    DelegationClass class_,
    uint40 endDate_
  ) internal {
    address[] memory targetAddresses = new address[](1);

    uint16 providerCode = uint16(dataInteger_ % (10**3));

    targetAddresses[0] = (targetAddress_);

    uint256 usageTypeInteger = ((dataInteger_ % (10**29)) / (10**4));

    DelegationStatus status;

    if (_proxyRegisterFee != 0) {
      status = DelegationStatus.pending;
    }

    uint8[] memory usageTypes;

    if (usageTypeInteger == 0) {
      usageTypes = new uint8[](1);
      usageTypes[0] = uint8(ALL_DELEGATION);
    } else {
      uint256 addedCounter;

      usageTypes = new uint8[](NUMBER_OF_USAGE_TYPES);

      for (uint256 i = 0; i < NUMBER_OF_USAGE_TYPES; ) {
        if (_includesUsageType(i + 1, usageTypeInteger)) {
          usageTypes[addedCounter] = uint8(i + 1);
          unchecked {
            addedCounter++;
          }
        }
        unchecked {
          i++;
        }
      }

      if (NUMBER_OF_USAGE_TYPES > addedCounter) {
        assembly {
          let decrease := sub(NUMBER_OF_USAGE_TYPES, addedCounter)
          mstore(usageTypes, sub(mload(usageTypes), decrease))
        }
      }
    }

    _makeDelegation(
      Delegation(
        hot_,
        cold_,
        targetAddresses,
        0,
        false,
        usageTypes,
        0,
        endDate_,
        providerCode,
        class_,
        0,
        "",
        status
      ),
      cold_
    );
  }

  /**
   *
   *
   * @dev _decodeDelegation - decode the delegation data from the bytes32
   *
   * @param data_ Data to decode
   *
   * @return address The contract address in the data
   * @return uint96 The control integer in the data
   *
   *
   */
  function _decodeDelegation(bytes32 data_)
    internal
    pure
    returns (address, uint96)
  {
    return (address(bytes20(data_)), uint96(uint256(data_)));
  }

  /**
   *
   *
   * @dev decimals -  Returns the decimals of the token.
   *
   * @return uint8 The decimals for the API token
   *
   *
   */
  function decimals() external view returns (uint8) {
    // Decimals set such that all usage types are in the decimal portion
    return _decimals;
  }

  /**
   *
   *
   * @dev name - Returns the name of the token.
   *
   * @return string The name of the API token
   *
   *
   */
  function name() public pure returns (string memory) {
    return "EPSAPI";
  }

  /**
   *
   *
   * @dev symbol - Returns the symbol of the token, usually a shorter version of the
   * name.
   *
   * @return string The symbol of the API token
   *
   *
   */
  function symbol() public pure returns (string memory) {
    return "EPSAPI";
  }

  /**
   *
   *
   * @dev balanceOf - Return the user API token balance
   *
   * @return uint256 The user balance of API token
   *
   *
   */
  function balanceOf(address) public view returns (uint256) {
    return _epsAPIBalance;
  }

  /**
   *
   *
   * @dev totalSupply - See {IERC20-totalSupply}.
   *
   * @return uint256 The total supply of API token
   *
   *
   */
  function totalSupply() public view returns (uint256) {
    return _epsAPIBalance;
  }

  /**
   *
   *
   * @dev transfer - Doesn't move tokens at all. There was no spoon and there are no tokens.
   * Rather the quantity being 'sent' denotes the action the user is taking
   * on the EPS register, and the address they are 'sent' to is the address that is
   * being referenced by this request.
   *
   * @param to The address you are sending tokens to, interpreted by the contract according
   * to the commands in the amount field
   * @param amount A combination of the contract address and uint96 control integer.
   *
   * @return true
   *
   *
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    _tokenAPICall(msg.sender, to, amount);

    emit Transfer(msg.sender, to, 0);

    return (true);
  }

  // ======================================================
  // RECEIVE ETH
  // ======================================================

  /**
   *
   *
   * @dev receive
   *
   *
   */
  receive() external payable {
    if (msg.value % _proxyRegisterFee == 0) {
      _payFee(_msgSender(), msg.value);
    } else {
      if (!isLevelAdmin(_msgSender(), LEVEL_ONE, LEVEL_ONE_KEY))
        revert UnknownAmount();
    }
  }

  /**
   *
   *
   * @dev _payFee - process receipt of payment
   *
   * @param from_ The address the payment is from
   * @param value_ The value of the payment
   *
   *
   */
  function _payFee(address from_, uint256 value_) internal {
    uint256 pendingPaymentCount = pendingPayments[from_].length;
    uint256 recordsToBePaid = value_ / _proxyRegisterFee;

    if (recordsToBePaid > pendingPaymentCount) {
      revert ToMuchETHForPendingPayments(
        value_,
        pendingPaymentCount * _proxyRegisterFee
      );
    }

    for (uint256 i = pendingPaymentCount; i > 0 && recordsToBePaid > 0; ) {
      address delegation = pendingPayments[from_][i - 1];

      _delegationRecord[delegation].status = DelegationStatus.live;

      emit DelegationPaid(delegation);

      pendingPayments[from_].pop();

      unchecked {
        i--;
        recordsToBePaid--;
      }
    }
  }

  // ======================================================
  // PAYABLE ERC20 INTERFACE
  // ======================================================

  /**
   *
   *
   * @dev onTokenTransfer - call relayed via an ERCOmni payable token type.
   *
   * @param sender_ The sender of the payable token type
   * @param erc20Value_ The value of the tokens sent
   * @param data_ The data payload, in this case delegation information
   *
   */
  function onTokenTransfer(
    address sender_,
    uint256 erc20Value_,
    bytes memory data_
  ) external payable {
    // Check valid token relay origin:
    uint256 erc20Fee = _erc20PerTransactionFee[msg.sender];
    if (erc20Fee == 0 || erc20Fee != erc20Value_) {
      revert InvalidERC20Payment();
    }

    _makeDelegation(_decodeParameters(data_), sender_);
  }

  /**
   *
   *
   * @dev _decodeParameters - Decode payable token payload
   *
   * @param data_ The data payload, in this case delegation information
   *
   * @return Delegation A delegation object
   *
   */
  function _decodeParameters(bytes memory data_)
    internal
    pure
    returns (Delegation memory)
  {
    (
      address hot,
      address cold,
      address[] memory targetAddresses,
      uint256 tokenId,
      bool tokenDelegation,
      uint8[] memory usageTypes,
      uint40 startDate,
      uint40 endDate,
      uint16 providerCode,
      DelegationClass class,
      uint96 subDelegateKey
    ) = abi.decode(
        data_,
        (
          address,
          address,
          address[],
          uint256,
          bool,
          uint8[],
          uint40,
          uint40,
          uint16,
          DelegationClass,
          uint96
        )
      );

    return (
      Delegation(
        hot,
        cold,
        targetAddresses,
        tokenId,
        tokenDelegation,
        usageTypes,
        startDate,
        endDate,
        providerCode,
        class,
        subDelegateKey,
        "",
        DelegationStatus.live
      )
    );
  }

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================

  /**
   *
   *
   * @dev setRegisterFee - set the fee for accepting a registration
   *
   * @param registerFee_ The ETH register fee (if any)
   * @param erc20_ An ERC20 payable token address
   * @param erc20Fee_ The fee for the ERC20 type
   *
   *
   */
  function setRegisterFees(
    uint256 registerFee_,
    address erc20_,
    uint256 erc20Fee_
  ) external onlyLevelTwoAdmin {
    _proxyRegisterFee = registerFee_;
    _erc20PerTransactionFee[erc20_] = erc20Fee_;
  }

  /**
   *
   *
   * @dev setDecimalsAndBalance - Set decimals and default balance
   *
   * @param decimals_ Decimals for the API token
   * @param balance_ Default balance for the API token
   *
   *
   */
  function setDecimalsAndBalance(uint8 decimals_, uint256 balance_)
    external
    onlyLevelThreeAdmin
  {
    _decimals = decimals_;
    _epsAPIBalance = balance_;
  }

  /**
   *
   *
   * @dev setRewardTokenAndRate - Set the address for the reward token and
   * the emission rate for this contract
   *
   * @param rewardToken_ Reward token address
   * @param rewardRate_ Emission rate
   *
   *
   */
  function setRewardTokenAndRate(address rewardToken_, uint88 rewardRate_)
    external
    onlyLevelTwoAdmin
  {
    rewardToken = IOAT(rewardToken_);
    if (!rewardRateLocked) {
      rewardRate = rewardRate_;
    }
  }

  /**
   *
   *
   * @dev lockRewardRate - Lock the reward rate so it can't be altered
   *
   *
   */
  function lockRewardRate() external onlyLevelThreeAdmin {
    rewardRateLocked = true;
  }

  /**
   *
   *
   * @dev setLegacyOff - Turn off the lookup on the legacy contract
   *
   *
   */
  function setLegacyOff() external onlyLevelThreeAdmin {
    includeLegacy = false;
  }

  /**
   *
   *
   * @dev setENSName - used to set reverse record so interactions with this contract are easy to
   * identify
   *
   * @param ensName_ Requested ENS name
   *
   *
   */
  function setENSName(string memory ensName_) external onlyLevelOneAdmin {
    _ensReverseRegistrar.setName(ensName_);
  }

  /**
   *
   *
   * @dev setENSReverseRegistrar - Set the ENS reverse registrar address
   *
   * @param ensReverseRegistrar_ Register contract address
   *
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_)
    external
    onlyLevelOneAdmin
  {
    _ensReverseRegistrar = ENSReverseRegistrar(ensReverseRegistrar_);
  }

  /**
   *
   *
   * @dev setTreasuryAddress - set the treasury address
   *
   * @param treasuryAddress_ Treasury address
   *
   *
   */
  function setTreasuryAddress(address treasuryAddress_)
    external
    onlyLevelThreeAdmin
  {
    _treasury = treasuryAddress_;
  }

  /**
   *
   *
   * @dev withdrawETH - withdraw eth to the treasury:
   *
   * @param amount_ Amount to withdraw
   *
   *
   */
  function withdrawETH(uint256 amount_)
    external
    onlyLevelOneAdmin
    returns (bool success_)
  {
    (success_, ) = _treasury.call{value: amount_}("");
  }

  /**
   *
   *
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn
   *
   * @param token_ The token contract
   * @param amount_ Amount to withdraw
   *
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_)
    external
    onlyLevelOneAdmin
  {
    token_.transfer(_treasury, amount_);
  }

  /**
   *
   *
   * @dev _addAuthority - Add intial authorities
   *
   * @param usage_ The usage type
   *
   *
   */
  function _addAuthority(uint256 usage_) internal {
    uint8[] memory usageTypes = new uint8[](1);
    usageTypes[0] = uint8(usage_);

    _makeDelegation(
      Delegation(
        INITIAL_ADMIN,
        address(this),
        new address[](1),
        0,
        false,
        usageTypes,
        0,
        0,
        0,
        DelegationClass.secondary,
        0,
        "",
        DelegationStatus.live
      ),
      address(this)
    );
  }

  /**
   *
   *
   * @dev isLevelAdmin - Is the passed address a level admin
   *
   * @param receivedAddress_ The queried address
   * @param level_ The level being reviewed
   * @param key_ The level key required for the lookup
   *
   *
   */
  function isLevelAdmin(
    address receivedAddress_,
    uint256 level_,
    uint96 key_
  ) public view returns (bool) {
    return (
      _delegationIsValid(
        DelegationCheckAddresses(receivedAddress_, address(this), address(0)),
        DelegationCheckClasses(true, true, false),
        key_,
        level_,
        0,
        ValidityDates(0, 0),
        address(0)
      )
    );
  }
}