// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/GuardianTimeMath.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IERC11554KController.sol";

/**
 * @dev Guardians management contract version 0.2.2
 * Sets guardians parameters, fees, info
 * by guardians themselves and the protocol.
 */
contract Guardians is Initializable, OwnableUpgradeable {
    /// @dev Guardian Info struct.
    struct GuardianInfo {
        /// @notice Hashed physical address of a guardian.
        bytes32 addressHash; //0
        /// @notice Logo of a guardian.
        string logo; //1
        /// @notice Name of a guardian.
        string name; //2
        /// @notice A guardian's redirect URI for future authentication flows.
        string redirect; //3
        /// @notice Guardian's policy.
        string policy; //4
        /// @notice Active status for a guardian
        bool isActive; //5
        /// @notice Private status for a guardian.
        bool isPrivate; //6
    }

    enum GuardianFeeRatePeriods {
        SECONDS,
        MINUTES,
        HOURS,
        DAYS
    }

    /// @dev Guardian class struct.
    struct GuardianClass {
        /// @notice Maximum insurance on-chain coverage.
        uint256 maximumCoverage; //0
        /// @notice Minting fee. Stored scaled by 10^18.
        uint256 mintingFee; //1
        /// @notice Redemption fee. Stored scaled by 10^18.
        uint256 redemptionFee; //2
        /// @notice The base unit for the guardian fee rate.
        uint256 guardianFeeRatePeriod; //3
        /// @notice Guardian fee rate per period. Stored scaled by 10^18.
        uint256 guardianFeeRate; //4
        /// @notice Guardian fee rate historic minimum.
        uint256 guardianFeeRateMinimum; //5
        /// @notice Last Guardian fee rate increase update timestamp.
        uint256 lastGuardianFeeRateIncrease; //6
        /// @notice Is guardian class active.
        bool isActive; //7
        /// @notice Guardian URI for metadata.
        string uri; //8
    }

    uint256 public constant SECOND = 1;
    uint256 public constant MINUTE = 60;
    uint256 public constant HOUR = MINUTE * 60;
    uint256 public constant DAY = HOUR * 24;

    /// @notice Fee manager contract.
    IFeesManager public feesManager;

    /// @notice Controller contract.
    IERC11554KController public controller;

    /// @notice Percentage factor with 0.01% precision. For internal float calculations.
    uint256 public constant PERCENTAGE_FACTOR = 10000;

    /// @notice Minimum minting request fee.
    uint256 public minimumRequestFee;
    /// @notice Minimum time window for guardian fee rate increase.
    uint256 public guardianFeeSetWindow;
    /// @notice Maximum guardian fee rate percentage increase during single fee set, 0.01% precision.
    uint256 public maximumGuardianFeeSet;
    /// @notice Minimum storage time an item needs to have for transfers.
    uint256 public minStorageTime;

    /// @notice Is an address a 4K whitelisted guardian.
    mapping(address => bool) public isWhitelisted;

    /// @notice Metadata info about a guardian
    mapping(address => GuardianInfo) public guardianInfo;

    /// @notice Guardians whitelisted users for services.
    mapping(address => mapping(address => bool)) public guardianWhitelist;
    /// @notice To whom (if) guardian delegated functions to execute
    mapping(address => address) public delegated;
    /// @notice  Guardian classes of a particular guardian.
    mapping(address => GuardianClass[]) public guardiansClasses;
    /// @notice How much items with id guardian keeps.
    /// guardian -> collection -> id -> amount
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public stored;
    /// @notice At which guardian is each item stored.
    /// collection address -> item id -> guardian address
    mapping(IERC11554K => mapping(uint256 => address)) public whereItemStored;

    /// @notice In which guardian class is the item? (within the context of the guardian where the item is stored)
    /// collection address -> item id -> guardian class index
    mapping(IERC11554K => mapping(uint256 => uint256)) public itemGuardianClass;

    /// @notice Mapping from a token holder address to a collection to an item id, to the date until storage has been paid.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public guardianFeePaidUntil;

    /// @notice Mapping from a collection, to item id, to the date until storage has been paid (globally, collectively for all users).
    /// @dev We need this for the movement of all items from one guardian to another.
    mapping(IERC11554K => mapping(uint256 => uint256))
        public globalItemGuardianFeePaidUntil;

    /// @notice user -> collection -> item id -> num items in repossession
    /// @notice Number of items in a collection that a user has in repossession.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public inRepossession;

    /// @notice guardian => delegatee => true if guardian delegates some functions to delegatee.
    mapping(address => mapping(address => bool)) public delegatedAll;

    /// @notice guardian => collection => delegatee if guardian delegates some functions to delegatee.
    mapping(address => mapping(IERC11554K => address))
        public delegatedCollection;

    /// @notice Version of the contract
    bytes32 public version;

    /// @dev Guardian has been added.
    event GuardianAdded(address indexed guardian, GuardianInfo newGuardianInfo);
    /// @dev Guardian has been removed.
    event GuardianRemoved(address indexed guardian);
    /// @dev Guardian has been modified
    event GuardianModified(
        address indexed guardian,
        uint8 fieldIndexModified,
        GuardianInfo newGuardianInfo
    );
    /// @dev Guardian class has been added.
    event GuardianClassAdded(
        address indexed guardian,
        uint256 classID,
        GuardianClass newGuardianClass
    );
    /// @dev Guardian class has been modified.
    event GuardianClassModified(
        address indexed guardian,
        uint256 classID,
        uint8 fieldIndexModified,
        GuardianClass newGuardianClass
    );

    /// @dev Item has been stored by the guardian
    event ItemStored(
        address indexed guardian,
        uint256 classID,
        uint256 tokenId,
        IERC11554K collection
    );

    /// @dev Item has been moved from one guardian to another
    event ItemMoved(
        address indexed fromGuardian,
        address indexed toGuardian,
        uint256 toGuardianClassId,
        uint256 tokenId,
        IERC11554K collection
    );

    /// @dev Storage time has been purchased for an item.
    event StorageTimeAdded(
        uint256 indexed id,
        address indexed guardian,
        uint256 timeAmount,
        address beneficiary,
        IERC11554K collection
    );
    /// @dev Item(s) have been set for repossession.
    event SetForRepossession(
        uint256 indexed id,
        IERC11554K indexed collection,
        address indexed guardian,
        uint256 amount
    );
    /// @dev Guardian has been added - with metadata.
    event GuardianRegistered(
        address indexed guardian,
        GuardianInfo newGuardianInfo
    );

    /// @dev Errors
    error GuardianNotWhitelisted();
    error CallerNotController();
    error NotCallersGuardianData();
    error MinStorageTimeTooLow();
    error TooManyReposessionItems();
    error OldGuardianAvailable();
    error NewGuardianUnavailable();
    error ClassNotActive();
    error NotGuardianOfItems();
    error FreeStorageItemsCantBeRepossessed();
    error GuardianFeePaidUntilStillInFuture();
    error NoItemsToRepossess();
    error MintingFeeTooLow();
    error DifferentPeriodRequired();
    error CollectionIsNotActiveOrLinked();
    error GuardianClassFeeRateTooLow();
    error GuardianFeeTooLow();
    error BeneficiaryDoesNotOwnItem();
    error GuardianDoesNotStoreItem();
    error ItemNotYetMinted();
    error GuardianFeeNotChangeableOnFreeStorageClass();
    error GuardianFeeWindowHasntPassed();
    error GuardianFeeRateLimitExceeded();

    /**
     * @dev Only whitelisted guardian modifier.
     */
    modifier onlyWhitelisted(address guardian) {
        if (!isWhitelisted[guardian]) {
            revert GuardianNotWhitelisted();
        }
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier onlyController() {
        if (_msgSender() != address(controller)) {
            revert CallerNotController();
        }
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier ifNotOwnerGuardianIsCaller(address guardian) {
        if (_msgSender() != owner()) {
            if (_msgSender() != guardian) {
                revert NotCallersGuardianData();
            }
        }
        _;
    }

    /**
     * @notice Initialize Guardians contract.
     * @param minimumRequestFee_ The minimum mint request fee.
     * @param guardianFeeSetWindow_ The window of time in seconds within a guardian is allowed to increase a guardian fee rate.
     * @param maximumGuardianFeeSet_ The max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR.
     * @param feesManager_ Fees manager contract address.
     * @param controller_ Controller contract address.
     * @param version_ Version of contract
     */
    function initialize(
        uint256 minimumRequestFee_,
        uint256 guardianFeeSetWindow_,
        uint256 maximumGuardianFeeSet_,
        IFeesManager feesManager_,
        IERC11554KController controller_,
        bytes32 version_
    ) external initializer {
        __Ownable_init();
        minimumRequestFee = minimumRequestFee_;
        guardianFeeSetWindow = guardianFeeSetWindow_;
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
        minStorageTime = 7776000; // default 90 days
        feesManager = feesManager_;
        controller = controller_;
        version = version_;
    }

    /**
     * @notice Set controller.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param controller_ New address of controller contract.
     */
    function setController(
        IERC11554KController controller_
    ) external virtual onlyOwner {
        controller = controller_;
    }

    /**
     * @notice Set fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     @param feesManager_ New address of fees manager contract.
     */
    function setFeesManager(
        IFeesManager feesManager_
    ) external virtual onlyOwner {
        feesManager = feesManager_;
    }

    /**
     * @notice Sets new min storage time.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param minStorageTime_ New minimum storage time that items require to have, in seconds.
     */
    function setMinStorageTime(
        uint256 minStorageTime_
    ) external virtual onlyOwner {
        if (minStorageTime_ == 0) {
            revert MinStorageTimeTooLow();
        }
        minStorageTime = minStorageTime_;
    }

    /**
     * @notice Sets minimum mining fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param minimumRequestFee_ New minumum mint request fee.
     */
    function setMinimumRequestFee(
        uint256 minimumRequestFee_
    ) external onlyOwner {
        minimumRequestFee = minimumRequestFee_;
    }

    /**
     * @notice Sets maximum Guardian fee rate set percentage.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param maximumGuardianFeeSet_ New max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR
     */
    function setMaximumGuardianFeeSet(
        uint256 maximumGuardianFeeSet_
    ) external onlyOwner {
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
    }

    /**
     * @notice Sets minimum Guardian fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardianFeeSetWindow_ New window of time in seconds within a guardian is allowed to increase a guardian fee rate
     */
    function setGuardianFeeSetWindow(
        uint256 guardianFeeSetWindow_
    ) external onlyOwner {
        guardianFeeSetWindow = guardianFeeSetWindow_;
    }

    /**
     * @notice Does a batch adding of storage for all the items passed.
     * @param collections Array of collections that contain the items for which guardian time will be purchased.
     * @param beneficiaries Array of addresses that will be receiving the purchased guardian time.
     * @param ids Array of item ids for which guardian time will be purchased.
     * @param guardianFeeAmounts Array of guardian fee inputs for purchasing guardian time.
     */
    function batchAddStorageTime(
        IERC11554K[] calldata collections,
        address[] calldata beneficiaries,
        uint256[] calldata ids,
        uint256[] calldata guardianFeeAmounts
    ) external virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            addStorageTime(
                collections[i],
                beneficiaries[i],
                ids[i],
                guardianFeeAmounts[i]
            );
        }
    }

    /**
     * @dev Externally called store item function by controller.
     * @param collection Address of the collection that the item being stored belongs to.
     * @param mintAddress Address of entity receiving the token(s).
     * @param id Item id of the item being stored.
     * @param guardian Address of guardian the item will be stored in.
     * @param guardianClassIndex Index of the guardian class the item will be stored in.
     * @param guardianFeeAmount Amount of fee that is being paid to purchase guardian time.
     * @param numItems Number of items being stored
     * @param feePayer The address of the entity paying the guardian fee.
     */
    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external virtual onlyController {
        stored[guardian][collection][id] += numItems;
        whereItemStored[collection][id] = guardian;
        itemGuardianClass[collection][id] = guardianClassIndex;

        // Only needs to be done in non-free guardian classes
        if (
            guardiansClasses[guardian][guardianClassIndex].guardianFeeRate > 0
        ) {
            // Initialize paid until timelines on first ever mints
            if (guardianFeePaidUntil[mintAddress][collection][id] == 0) {
                guardianFeePaidUntil[mintAddress][collection][id] = block
                    .timestamp;
            }
            if (globalItemGuardianFeePaidUntil[collection][id] == 0) {
                globalItemGuardianFeePaidUntil[collection][id] = block
                    .timestamp;
            }
            {
                uint256 addedStorageTime = GuardianTimeMath
                    .calculateAddedGuardianTime(
                        guardianFeeAmount,
                        guardiansClasses[guardian][guardianClassIndex]
                            .guardianFeeRate,
                        guardiansClasses[guardian][guardianClassIndex]
                            .guardianFeeRatePeriod,
                        numItems
                    );

                guardianFeePaidUntil[mintAddress][collection][
                    id
                ] += addedStorageTime;
                globalItemGuardianFeePaidUntil[collection][
                    id
                ] += addedStorageTime;

                emit StorageTimeAdded(
                    id,
                    guardian,
                    addedStorageTime,
                    mintAddress,
                    collection
                );
            }

            feesManager.payGuardianFee(
                guardianFeeAmount,
                (guardiansClasses[guardian][guardianClassIndex]
                    .guardianFeeRate * numItems) /
                    getGuardianFeeRatePeriod(guardian, guardianClassIndex),
                guardian,
                guardianFeePaidUntil[mintAddress][collection][id],
                feePayer,
                paymentAsset
            );

            emit ItemStored(guardian, guardianClassIndex, id, collection);
        }
    }

    /**
     * @dev Externally called take item out function by controller.
     * @param guardian Address of guardian the item is being stored in.
     * @param collection Address of the collection that the item being stored belongs to.
     * @param id Item id of the item being stored.
     * @param numItems Number of items that are being taken out of the guardian.
     * @param from Address of the entity requesting the redemption/removal of the item(s).
     */
    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external virtual onlyController {
        if (inRepossession[from][collection][id] >= numItems) {
            revert TooManyReposessionItems();
        }
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            itemGuardianClass[collection][id]
        );

        uint256 guardianFeeRatePeriod = getGuardianFeeRatePeriod(
            guardian,
            itemGuardianClass[collection][id]
        );

        // No refunds
        // uint256 previousPaidUntil = guardianFeePaidUntil[from][collection][id];
        // uint256 guardianFeeRefundAmount;

        if (guardianClassFeeRate > 0) {
            // No refunds
            // guardianFeeRefundAmount =
            _shiftGuardianFeesOnTokenRedeem(
                from,
                collection,
                id,
                numItems,
                guardianClassFeeRate,
                guardianFeeRatePeriod
            );
        }

        stored[guardian][collection][id] -= numItems;
        if (stored[guardian][collection][id] == 0) {
            whereItemStored[collection][id] = address(0);
        }

        // No refunds
        /*
        uint256 guardianClassFeeRateMin = getGuardianFeeRateMinimum(guardian, itemGuardianClass[collection][id]);
        if (guardianClassFeeRate > 0) {
            feesManager.refundGuardianFee(
                guardianFeeRefundAmount,
                (guardianClassFeeRateMin * numItems) / guardianFeeRatePeriod,
                guardian,
                previousPaidUntil,
                from,
                paymentAsset
            );
        }
        */
    }

    /**
     * @notice Moves items from inactive guardian to active guardian. Move ALL items,
     * in the case of semi-fungibles. Must pass a guardian classe for each item for the new guardian.
     *
     * Requirements:
     *
     * 1) The caller must be 4K.
     * 2) Old guardian must be inactive.
     * 3) New guardian must be active.
     * 4) Each class passed for each item for the new guardian must be active.
     * 5) Must only be used to move ALL items and have movement of guardian fees after moving ALL items.
     * @param collection Address of the collection that includes the items being moved.
     * @param ids Array of item ids being moved.
     * @param oldGuardian Address of the guardian items are being moved from.
     * @param newGuardian Address of the guardian items are being moved to.
     * @param newGuardianClassIndeces Array of the newGuardian's guardian class indices the items will be moved to.
     */
    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external virtual onlyOwner {
        if (isAvailable(oldGuardian)) {
            revert OldGuardianAvailable();
        }
        if (!isAvailable(newGuardian)) {
            revert NewGuardianUnavailable();
        }
        for (uint256 i = 0; i < ids.length; ++i) {
            if (!isClassActive(newGuardian, newGuardianClassIndeces[i])) {
                revert ClassNotActive();
            }
            _moveSingleItem(
                collection,
                ids[i],
                oldGuardian,
                newGuardian,
                newGuardianClassIndeces[i]
            );
        }
    }

    /**
     * @notice Copies all guardian classes from one guardian to another.
     * @dev If new guardian has no guardian classes before this, class indeces will be the same. If not, copies classes will have new indeces.
     *
     * @param oldGuardian Address of the guardian whose classes will be moved.
     * @param newGuardian Address of the guardian that will be receiving the classes.
     */
    function copyGuardianClasses(
        address oldGuardian,
        address newGuardian
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < guardiansClasses[oldGuardian].length; i++) {
            _copyGuardianClass(oldGuardian, newGuardian, i);
        }
    }

    /**
     * @notice Function for the guardian to set item(s) to be flagged for repossession.
     * @param collection Collection that contains the item to be repossessed.
     * @param itemId Id of item(s) being reposessed.
     * @param owner Current owner of the item(s).
     */
    function setItemsToRepossessed(
        IERC11554K collection,
        uint256 itemId,
        address owner
    ) external {
        if (whereItemStored[collection][itemId] != _msgSender()) {
            revert NotGuardianOfItems();
        }
        if (getGuardianFeeRateByCollectionItem(collection, itemId) == 0) {
            revert FreeStorageItemsCantBeRepossessed();
        }
        if (
            guardianFeePaidUntil[owner][collection][itemId] >= block.timestamp
        ) {
            revert GuardianFeePaidUntilStillInFuture();
        }

        uint256 currAmount = IERC11554K(collection).balanceOf(owner, itemId);
        if (currAmount == 0) {
            revert NoItemsToRepossess();
        }

        uint256 prevInReposession = inRepossession[owner][collection][itemId];
        inRepossession[owner][collection][itemId] = currAmount;

        emit SetForRepossession(
            itemId,
            collection,
            _msgSender(),
            currAmount - prevInReposession
        );
    }

    /**
     * @notice Sets activity mode for the guardian. Either active or not.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose activity mode will be set.
     * @param activity Boolean for guardian activity mode.
     */
    function setActivity(
        address guardian,
        bool activity
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].isActive = activity;
        emit GuardianModified(guardian, 5, guardianInfo[guardian]);
    }

    /**
     * @notice Sets privacy mode for the guardian. Either public false or private true.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose privacy mode will be set.
     * @param privacy Boolean for guardian privacy mode.
     */
    function setPrivacy(
        address guardian,
        bool privacy
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].isPrivate = privacy;
        emit GuardianModified(guardian, 4, guardianInfo[guardian]);
    }

    /**
     * @notice Sets logo for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose logo will be set.
     * @param logo URI of logo for guardian.
     */
    function setLogo(
        address guardian,
        string calldata logo
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].logo = logo;
        emit GuardianModified(guardian, 1, guardianInfo[guardian]);
    }

    /**
     * @notice Sets name for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose name will be set.
     * @param name Name of guardian.
     */
    function setName(
        address guardian,
        string calldata name
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].name = name;
        emit GuardianModified(guardian, 2, guardianInfo[guardian]);
    }

    /**
     * @notice Sets physical address hash for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose physical address will be set.
     * @param physicalAddressHash Bytes hash of physical address of the guardian.
     */
    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].addressHash = physicalAddressHash;
        emit GuardianModified(guardian, 0, guardianInfo[guardian]);
    }

    /**
     * @notice Sets policy for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose policy will be set.
     * @param policy Guardian policy.
     */
    function setPolicy(
        address guardian,
        string calldata policy
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].policy = policy;
        emit GuardianModified(guardian, 4, guardianInfo[guardian]);
    }

    /**
     * @notice Sets redirects for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose redirect URI will be set.
     * @param redirect Redirect URI for guardian.
     */
    function setRedirect(
        address guardian,
        string calldata redirect
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].redirect = redirect;
        emit GuardianModified(guardian, 3, guardianInfo[guardian]);
    }

    /**
     * @notice Adds or removes users addresses to guardian whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose users whitelist status will be modified.
     * @param users Array of user addresses whose whitelist status will be modified.
     * @param whitelistStatus Boolean for the whitelisted status of the users.
     */
    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[guardian][users[i]] = whitelistStatus;
        }
    }

    /**
     * @notice Removes guardian from the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian address of guardian who will be removed.
     */
    function removeGuardian(address guardian) external virtual onlyOwner {
        isWhitelisted[guardian] = false;
        guardianInfo[guardian].isActive = false;
        emit GuardianRemoved(guardian);
    }

    /**
     * @notice Sets minting fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class minting fee will be modified.
     * @param classID Guardian's guardian class index whose minting fee will be modified.
     * @param mintingFee New minting fee. Minting fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        if (mintingFee < minimumRequestFee) {
            revert MintingFeeTooLow();
        }
        guardiansClasses[guardian][classID].mintingFee = mintingFee;
        emit GuardianClassModified(
            guardian,
            classID,
            1,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @notice Sets redemption fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner
     * @param guardian Address of the guardian whose guardian class redemption fee will be modified.
     * @param classID Guardian's guardian class index whose redemption fee will be modified.
     * @param redemptionFee New redemption fee. Redemption fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].redemptionFee = redemptionFee;
        emit GuardianClassModified(
            guardian,
            classID,
            2,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @notice Sets Guardian fee rate for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        _setGuardianClassGuardianFeeRate(
            guardian,
            classID,
            guardianFeeRate,
            guardiansClasses[guardian][classID].guardianFeeRatePeriod
        );
    }

    /**
     * @notice Sets Guardian fee rate and guardian fee rate period for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRatePeriod New guardian fee rate period.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        uint256 newPeriodMultiple;
        if (guardianFeeRatePeriod == GuardianFeeRatePeriods.SECONDS) {
            newPeriodMultiple = SECOND;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.MINUTES) {
            newPeriodMultiple = MINUTE;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.HOURS) {
            newPeriodMultiple = HOUR;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.DAYS) {
            newPeriodMultiple = DAY;
        }
        if (
            guardiansClasses[guardian][classID].guardianFeeRatePeriod ==
            newPeriodMultiple
        ) {
            revert DifferentPeriodRequired();
        }
        _setGuardianClassGuardianFeeRate(
            guardian,
            classID,
            guardianFeeRate,
            newPeriodMultiple
        );

        guardiansClasses[guardian][classID]
            .guardianFeeRatePeriod = newPeriodMultiple;
        emit GuardianClassModified(
            guardian,
            classID,
            3,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @notice Sets URI for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or owner.
     * @param guardian Address of the guardian whose guardian class URI will be modified.
     * @param classID Guardian's guardian class index whose class URI will be modified.
     * @param uri New URI.
     */
    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].uri = uri;
        emit GuardianClassModified(
            guardian,
            classID,
            8,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @notice Sets guardian class as active or not active by guardian or owner
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or owner.
     * @param guardian Address of the guardian whose guardian class active status will be modified.
     * @param classID Guardian's guardian class index whose guardian class active status will be modified.
     * @param activeStatus New guardian class active status.
     */
    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].isActive = activeStatus;
        emit GuardianClassModified(
            guardian,
            classID,
            7,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @notice Sets maximum insurance coverage for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian.
     * @param guardian Address of the guardian whose guardian class maximum coverage will be modified.
     * @param classID Guardian's guardian class index whose guardian class maximum coverage will be modified.
     * @param maximumCoverage New guardian class maximum coverage.
     */
    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].maximumCoverage = maximumCoverage;
        emit GuardianClassModified(
            guardian,
            classID,
            0,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @dev Sets the version of the contract.
     * @param version_ New version of contract.
     */
    function setVersion(bytes32 version_) external virtual onlyOwner {
        version = version_;
    }

    /**
     * @dev Externally called store item function by controller to update Guardian fees on token transfer. Complex logic needed for semi-fungibles.
     * @param from Address of entity sending token(s).
     * @param to Address of entity receiving token(s).
     * @param id Token id of token(s) being sent.
     * @param amount Amount of tokens being sent.
     */
    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external virtual {
        if (
            !controller.isActiveCollection(_msgSender()) ||
            !controller.isLinkedCollection(_msgSender())
        ) {
            revert CollectionIsNotActiveOrLinked();
        }
        IERC11554K collection = IERC11554K(_msgSender());

        uint256 guardianClassFeeRate = getGuardianFeeRateByCollectionItem(
            collection,
            id
        );

        uint256 guardianClassFeeRatePeriod = getGuardianFeeRatePeriodByCollectionItem(
                collection,
                id
            );

        uint256 guardianFeeShiftAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                amount
            );

        uint256 remainingFeeAmountFrom = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                collection.balanceOf(from, id)
            );

        uint256 remainingFeeAmountTo = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[to][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                collection.balanceOf(to, id)
            );

        // Recalculate the remaining time with new params for FROM
        uint256 newAmountFrom = collection.balanceOf(from, id) - amount;
        if (newAmountFrom == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //default
        } else {
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                GuardianTimeMath.calculateAddedGuardianTime(
                    remainingFeeAmountFrom - guardianFeeShiftAmount,
                    guardianClassFeeRate,
                    guardianClassFeeRatePeriod,
                    newAmountFrom
                );
        }

        // Recalculate the remaining time with new params for TO
        uint256 newAmountTo = collection.balanceOf(to, id) + amount;
        guardianFeePaidUntil[to][collection][id] =
            block.timestamp +
            GuardianTimeMath.calculateAddedGuardianTime(
                remainingFeeAmountTo + guardianFeeShiftAmount,
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                newAmountTo
            );
    }

    /**
     * @notice Adds guardian class to guardian by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian who is adding a new class.
     * @param maximumCoverage Max coverage of new guardian class.
     * @param mintingFee Minting fee of new guardian class. Minting fee must be passed as already scaled by 10^18 from real life value.
     * @param redemptionFee Redemption fee of new guardian class. Redemption fee must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRate Guardian fee rate of new guardian class. Guardian fee rate must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRatePeriod The size of the period unit for the guardian fee rate: per second, minute, hour, or day.
     */
    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
        returns (uint256 classID)
    {
        classID = _addGuardianClass(
            guardian,
            maximumCoverage,
            mintingFee,
            redemptionFee,
            guardianFeeRate,
            guardianFeeRatePeriod,
            uri
        );
    }

    /**
     * @notice Registers guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian Address of the new guardian.
     * @param name Name of new guardian.
     * @param logo URI of new guardian logo.
     * @param policy Policy of new guardian.
     * @param redirect Redirect URI of new guardian.
     * @param physicalAddressHash physical address hash of new guardian.
     * @param privacy Boolean - is the new guardian private or not.
     */
    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external virtual {
        guardianInfo[guardian].isActive = true;
        guardianInfo[guardian].name = name;
        guardianInfo[guardian].logo = logo;
        guardianInfo[guardian].policy = policy;
        guardianInfo[guardian].isPrivate = privacy;
        guardianInfo[guardian].redirect = redirect;
        guardianInfo[guardian].addressHash = physicalAddressHash;
        addGuardian(guardian);
        emit GuardianRegistered(guardian, guardianInfo[guardian]);
    }

    /**
     * @notice Delegates whole minting/redemption for all or single collection to `delegatee`
     * @param delegatee Address to which the calling guardian will delegate to.
     * @param collection If not zero address, then delegates processes only for this collection.
     */
    function delegate(
        address delegatee,
        IERC11554K collection
    ) external virtual onlyWhitelisted(_msgSender()) {
        if (address(collection) == address(0)) {
            delegatedAll[_msgSender()][delegatee] = true;
        } else {
            delegatedCollection[_msgSender()][collection] = delegatee;
        }
    }

    /**
     * @notice Undelegates whole minting/redemption for all or single collection from `delegatee`
     * @param delegatee Address to which the calling guardian will undelegate from.
     * @param collection If not zero address, then undelegates processes only for this collection.
     */
    function undelegate(
        address delegatee,
        IERC11554K collection
    ) external virtual onlyWhitelisted(_msgSender()) {
        if (address(collection) == address(0)) {
            delegatedAll[_msgSender()][delegatee] = false;
        } else {
            delegatedCollection[_msgSender()][collection] = address(0);
        }
    }

    /**
     * @notice Queries if the amount of guardian fee provided purchases the minimum guardian time for a particular guardian class.
     * @param guardianFeeAmount the amount of guardian fee being queried.
     * @param numItems Number of total items the guardian would be storing.
     * @param guardian Address of the guardian that would be doing the storing.
     * @param guardianClassIndex Index of guardian class that would be doing the storing.
     */
    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view virtual returns (bool) {
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );
        uint256 guardianFeeRatePeriod = getGuardianFeeRatePeriod(
            guardian,
            guardianClassIndex
        );

        if (guardianClassFeeRate == 0) {
            revert GuardianClassFeeRateTooLow();
        }

        return
            minStorageTime <=
            GuardianTimeMath.calculateAddedGuardianTime(
                guardianFeeAmount,
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                numItems
            );
    }

    /**
     * @notice Returns guardian class redemption fee.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's guardian class index being queried.
     * @return redemptionFee Guardian class's redemption fee. Returns scaled by 10^18 real life value.
     */
    function getRedemptionFee(
        address guardian,
        uint256 classID
    ) external view virtual returns (uint256) {
        return guardiansClasses[guardian][classID].redemptionFee;
    }

    /**
     * @notice Returns guardian class minting fee.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's guardian class index being queried.
     * @return mintingFee Guardian class's minting fee. Returns scaled by 10^18 real life value.
     */
    function getMintingFee(
        address guardian,
        uint256 classID
    ) external view virtual returns (uint256) {
        return guardiansClasses[guardian][classID].mintingFee;
    }

    /**
     * @notice Returns guardian classes number.
     * @param guardian Address of guardian whose guardian classes are being queried.
     * @return count How many guardian classes the guardian has.
     */
    function guardianClassesCount(
        address guardian
    ) external view virtual returns (uint256) {
        return guardiansClasses[guardian].length;
    }

    /**
     * @notice Checks if delegator delegated collection handling to delegatee.
     * @param collection Delegator guardian address.
     * @param delegatee Delegatee address.
     * @param collection Collection address.
     * @return true if delegated, false otherwise.
     */
    function isDelegated(
        address delegator,
        address delegatee,
        IERC11554K collection
    ) external view virtual returns (bool) {
        return
            delegatedCollection[delegator][collection] == delegatee ||
            delegatedAll[delegator][delegatee];
    }

    /**
     * @notice Adds guardian to the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian Address of the new guardian.
     */
    function addGuardian(address guardian) public virtual onlyOwner {
        isWhitelisted[guardian] = true;
        guardianInfo[guardian].isActive = true;
        emit GuardianAdded(guardian, guardianInfo[guardian]);
    }

    /**
     * @notice Anyone can add Guardian fees to a guardian holding an item.
     * @param collection Address of the collection the item belongs to.
     * @param beneficiary The address of the holder of the item.
     * @param itemId Id of the item.
     * @param guardianFeeAmount The amount of guardian fee being paid.
     */
    function addStorageTime(
        IERC11554K collection,
        address beneficiary,
        uint256 itemId,
        uint256 guardianFeeAmount
    ) public virtual {
        uint256 currAmount = collection.balanceOf(beneficiary, itemId);

        address guardian = whereItemStored[collection][itemId];
        uint256 guardianClassIndex = itemGuardianClass[collection][itemId];

        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );
        if (guardianClassFeeRate == 0) {
            revert GuardianClassFeeRateTooLow();
        }
        if (guardianFeeAmount == 0) {
            revert GuardianFeeTooLow();
        }
        if (currAmount == 0) {
            revert BeneficiaryDoesNotOwnItem();
        }
        if (guardian == address(0)) {
            revert GuardianDoesNotStoreItem();
        }
        {
            uint256 addedStorageTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    guardianFeeAmount,
                    guardianClassFeeRate,
                    getGuardianFeeRatePeriod(guardian, guardianClassIndex),
                    currAmount
                );

            guardianFeePaidUntil[beneficiary][collection][
                itemId
            ] += addedStorageTime;
            globalItemGuardianFeePaidUntil[collection][
                itemId
            ] += addedStorageTime;
            emit StorageTimeAdded(
                itemId,
                guardian,
                addedStorageTime,
                beneficiary,
                collection
            );
        }

        feesManager.payGuardianFee(
            guardianFeeAmount,
            (guardianClassFeeRate * currAmount) /
                getGuardianFeeRatePeriod(guardian, guardianClassIndex),
            guardian,
            guardianFeePaidUntil[beneficiary][collection][itemId],
            _msgSender(),
            controller.paymentToken()
        );
    }

    /**
     * @notice Returns guardian class guardian fee rate of the stored item in collection with  itemId.
     * @param collection Address of the collection where the item being queried belongs to.
     * @param itemId Item id of item whose guardian fee rate is being queried.
     * @return guardianFeeRate Fee rate of the item being queried (of guardian class it's in). Returns scaled by 10^18 real life value.
     */
    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) public view virtual returns (uint256) {
        if (collection.totalSupply(itemId) == 0) {
            revert ItemNotYetMinted();
        }
        return
            guardiansClasses[whereItemStored[collection][itemId]][
                itemGuardianClass[collection][itemId]
            ].guardianFeeRate;
    }

    /**
     * @notice Returns guardian class guardian fee rate period size of the stored item in collection with  itemId.
     * @param collection Address of the collection where the item being queried belongs to.
     * @param itemId Item id of item whose guardian fee rate is being queried.
     * @return guardianFeeRatePeriod Size of the item being queried (of guardian class it's in).
     */
    function getGuardianFeeRatePeriodByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) public view virtual returns (uint256) {
        if (collection.totalSupply(itemId) == 0) {
            revert ItemNotYetMinted();
        }
        return
            guardiansClasses[whereItemStored[collection][itemId]][
                itemGuardianClass[collection][itemId]
            ].guardianFeeRatePeriod;
    }

    /**
     * @notice Returns true if the guardian is active and whitelisted.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @return boolean Is the guardian active and whitelisted.
     */
    function isAvailable(address guardian) public view returns (bool) {
        return isWhitelisted[guardian] && guardianInfo[guardian].isActive;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return guardianFeeRate The guardian class guardian fee rate. Returns scaled by 10^18 real life value.
     */
    function getGuardianFeeRate(
        address guardian,
        uint256 classID
    ) public view virtual returns (uint256) {
        return guardiansClasses[guardian][classID].guardianFeeRate;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate period size.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return guardianFeeRatePeriod The unit of time for the guardian fee rate.
     */
    function getGuardianFeeRatePeriod(
        address guardian,
        uint256 classID
    ) public view virtual returns (uint256) {
        return guardiansClasses[guardian][classID].guardianFeeRatePeriod;
    }

    /**
     * @notice Returns guardian class classID activity true/false.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return activeStatus Boolean - is the class active or not.
     */
    function isClassActive(
        address guardian,
        uint256 classID
    ) public view virtual returns (bool) {
        return guardiansClasses[guardian][classID].isActive;
    }

    /**
     * @dev Internal call, adds guardian class.
     */
    function _addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) internal virtual returns (uint256 classID) {
        classID = guardiansClasses[guardian].length;

        uint256 periodMultiple;
        if (guardianFeeRatePeriod == GuardianFeeRatePeriods.SECONDS) {
            periodMultiple = SECOND;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.MINUTES) {
            periodMultiple = MINUTE;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.HOURS) {
            periodMultiple = HOUR;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.DAYS) {
            periodMultiple = DAY;
        }

        guardiansClasses[guardian].push(
            GuardianClass(
                maximumCoverage,
                mintingFee,
                redemptionFee,
                periodMultiple,
                guardianFeeRate,
                guardianFeeRate,
                block.timestamp,
                true,
                uri
            )
        );
        emit GuardianClassAdded(
            guardian,
            classID,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @dev Internal call, copies an ENTIRE guardian class from one guardian to another. Note: same data but DIFFERENT index.
     */
    function _copyGuardianClass(
        address oldGuardian,
        address newGuardian,
        uint256 oldGuardianClassIndex
    ) internal returns (uint256 classID) {
        classID = guardiansClasses[newGuardian].length;
        guardiansClasses[newGuardian].push(
            GuardianClass(
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .maximumCoverage,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].mintingFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .redemptionFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRatePeriod,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRate,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRateMinimum,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .lastGuardianFeeRateIncrease,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].isActive,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].uri
            )
        );
        emit GuardianClassAdded(
            newGuardian,
            classID,
            guardiansClasses[newGuardian][classID]
        );
    }

    /**
     * @dev Internal call, sets a new guardian class guardian fee rate, with several checks. Compensates for a different period multiple
     */
    function _setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate,
        uint256 newPeriodMultiple
    ) internal virtual {
        if (guardianFeeRate == 0) {
            revert GuardianClassFeeRateTooLow();
        }

        if (guardiansClasses[guardian][classID].guardianFeeRate == 0) {
            revert GuardianFeeNotChangeableOnFreeStorageClass();
        }

        uint256 currentPeriodMultiple = guardiansClasses[guardian][classID]
            .guardianFeeRatePeriod;
        if (
            (guardianFeeRate / newPeriodMultiple) >
            (guardiansClasses[guardian][classID].guardianFeeRate /
                currentPeriodMultiple)
        ) {
            if (
                block.timestamp <
                guardiansClasses[guardian][classID]
                    .lastGuardianFeeRateIncrease +
                    guardianFeeSetWindow
            ) {
                revert GuardianFeeWindowHasntPassed();
            }

            if (
                (guardianFeeRate / newPeriodMultiple) >
                (guardiansClasses[guardian][classID].guardianFeeRate *
                    maximumGuardianFeeSet) /
                    (currentPeriodMultiple * PERCENTAGE_FACTOR)
            ) {
                revert GuardianFeeRateLimitExceeded();
            }

            guardiansClasses[guardian][classID]
                .lastGuardianFeeRateIncrease = block.timestamp;
        }
        guardiansClasses[guardian][classID].guardianFeeRate = guardianFeeRate;
        if (
            (guardianFeeRate / newPeriodMultiple) <
            (guardiansClasses[guardian][classID].guardianFeeRateMinimum /
                currentPeriodMultiple)
        ) {
            guardiansClasses[guardian][classID]
                .guardianFeeRateMinimum = guardianFeeRate;
        }
        emit GuardianClassModified(
            guardian,
            classID,
            4,
            guardiansClasses[guardian][classID]
        );
    }

    /**
     * @dev Internal call that is done on each item token redeem to
     * relaculate paid storage time, guardian fees.
     */
    function _shiftGuardianFeesOnTokenRedeem(
        address from,
        IERC11554K collection,
        uint256 id,
        uint256 redeemAmount,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod
    ) internal virtual returns (uint256) {
        uint256 originalTimeRemaining = guardianFeePaidUntil[from][collection][
            id
        ];

        // Recalculate the remaining time with new params
        uint256 bal = IERC11554K(collection).balanceOf(from, id);

        // Total fee that remains
        uint256 remainingFeeAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                bal
            );

        // Portion of fee we're giving back, for refund.
        uint256 guardianFeeRefundAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                redeemAmount
            );

        if (bal - redeemAmount == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //back to default,0
        } else {
            uint256 recalculatedTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    remainingFeeAmount - guardianFeeRefundAmount,
                    guardianClassFeeRate,
                    guardianFeeRatePeriod,
                    bal - redeemAmount
                );
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                recalculatedTime;
        }

        if (IERC11554K(collection).totalSupply(id) - redeemAmount == 0) {
            globalItemGuardianFeePaidUntil[collection][id] = 0;
        } else {
            uint256 timeDelta;
            if (
                originalTimeRemaining >
                guardianFeePaidUntil[from][collection][id]
            ) {
                timeDelta = (originalTimeRemaining -
                    guardianFeePaidUntil[from][collection][id]);
            } else {
                timeDelta = (guardianFeePaidUntil[from][collection][id] -
                    originalTimeRemaining);
            }
            globalItemGuardianFeePaidUntil[collection][id] -= timeDelta;
        }

        return guardianFeeRefundAmount;
    }

    function _moveSingleItem(
        IERC11554K collection,
        uint256 itemId,
        address oldGuardian,
        address newGuardian,
        uint256 newGuardianClassIndex
    ) internal virtual {
        uint256 amount = stored[oldGuardian][collection][itemId];
        stored[oldGuardian][collection][itemId] = 0;
        stored[newGuardian][collection][itemId] += amount;
        whereItemStored[collection][itemId] = newGuardian;
        itemGuardianClass[collection][itemId] = newGuardianClassIndex;

        emit ItemMoved(
            oldGuardian,
            newGuardian,
            newGuardianClassIndex,
            itemId,
            collection
        );
    }
}