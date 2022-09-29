// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IStableCoin.sol";
import "../interfaces/IJPEGCardsCigStaking.sol";
import "../interfaces/IUniswapV2Oracle.sol";

/// @title NFT lending vault
/// @notice This contracts allows users to borrow PETH using NFTs as collateral.
/// The floor price of the NFT collection is fetched using a chainlink oracle, while some other more valuable traits
/// can have an higher price set by the DAO. Users can also increase the price (and thus the borrow limit) of their
/// NFT by submitting a governance proposal. If the proposal is approved the user can lock a percentage of the new price
/// worth of JPEG to make it effective
contract PETHNFTVault is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStableCoin;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    error InvalidNFT(uint256 nftIndex);
    error InvalidRate(Rate rate);
    error InvalidNFTType(bytes32 nftType);
    error InvalidUnlockTime(uint256 unlockTime);
    error InvalidAmount(uint256 amount);
    error InvalidPosition(uint256 nftIndex);
    error PositionLiquidated(uint256 nftIndex);
    error Unauthorized();
    error DebtCapReached();
    error InvalidInsuranceMode();
    error NoDebt();
    error NonZeroDebt(uint256 debtAmount);
    error PositionInsuranceExpired(uint256 nftIndex);
    error PositionInsuranceNotExpired(uint256 nftIndex);
    error ZeroAddress();
    error InvalidOracleResults();
    error NoOracleSet();
    error UnknownAction(uint8 action);

    event PositionOpened(address indexed owner, uint256 indexed index);
    event Borrowed(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );
    event Repaid(address indexed owner, uint256 indexed index, uint256 amount);
    event PositionClosed(address indexed owner, uint256 indexed index);
    event Liquidated(
        address indexed liquidator,
        address indexed owner,
        uint256 indexed index,
        bool insured
    );
    event Repurchased(address indexed owner, uint256 indexed index);
    event InsuranceExpired(address indexed owner, uint256 indexed index);
    event DaoFloorChanged(uint256 newFloor);
    event JPEGLocked(
        address indexed owner,
        uint256 indexed index,
        uint256 amount,
        uint256 unlockTime
    );
    event JPEGUnlocked(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );

    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
    }

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    struct JPEGLock {
        address owner;
        uint256 unlockAt;
        uint256 lockedValue;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate cigStakedCreditLimitRate;
        Rate cigStakedLiquidationLimitRate;
        Rate valueIncreaseLockRate;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuranceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    bytes32 private constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 private constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    //accrue required
    uint8 private constant ACTION_BORROW = 0;
    uint8 private constant ACTION_REPAY = 1;
    uint8 private constant ACTION_CLOSE_POSITION = 2;
    uint8 private constant ACTION_LIQUIDATE = 3;
    //no accrue required
    uint8 private constant ACTION_REPURCHASE = 100;
    uint8 private constant ACTION_CLAIM_NFT = 101;
    uint8 private constant ACTION_TRAIT_BOOST = 102;
    uint8 private constant ACTION_UNLOCK_JPEG = 103;

    IStableCoin public stablecoin;
    /// @notice Chainlink JPEG/ETH price feed
    IUniswapV2Oracle public jpegOracle;
    /// @notice Chainlink NFT floor oracle
    IAggregatorV3Interface public floorOracle;
    /// @notice Chainlink NFT fallback floor oracle
    IAggregatorV3Interface public fallbackOracle;
    /// @notice The JPEG token
    /// @custom:oz-renamed-from jpegLocker
    IERC20Upgradeable public jpeg;
    /// @notice JPEGCardsCigStaking, cig stakers get an higher credit limit rate and liquidation limit rate.
    /// Immediately reverts to normal rates if the cig is unstaked.
    IJPEGCardsCigStaking public cigStaking;
    IERC721Upgradeable public nftContract;

    /// @notice If true, the floor price won't be fetched using the Chainlink oracle but
    /// a value set by the DAO will be used instead
    bool public daoFloorOverride;
    // @notice If true, the floor price will be fetched using the fallback oracle
    bool public useFallbackOracle;
    /// @notice Total outstanding debt
    uint256 public totalDebtAmount;
    /// @dev Last time debt was accrued. See {accrue} for more info
    uint256 private totalDebtAccruedAt;
    uint256 public totalFeeCollected;
    uint256 private totalDebtPortion;

    VaultSettings public settings;

    /// @dev Keeps track of all the NFTs used as collateral for positions
    EnumerableSetUpgradeable.UintSet private positionIndexes;

    mapping(uint256 => Position) public positions;
    mapping(uint256 => address) public positionOwner;
    /// @custom:oz-renamed-from nftTypeValueETH
    mapping(bytes32 => uint256) private unused1; //unused after upgrade
    /// @custom:oz-renamed-from nftValueETH
    mapping(uint256 => uint256) private unused2; //unused after upgrade
    //bytes32(0) is floor
    mapping(uint256 => bytes32) public nftTypes;

    /// @notice Value of floor set by the DAO. Only used if `daoFloorOverride` is true
    uint256 private overriddenFloorValueETH;

    uint256 public minJPEGToLock;
    /// @notice The trait value multiplier for non floor NFTs. See {applyTraitBoost} for more info.
    mapping(bytes32 => Rate) public nftTypeValueMultiplier;
    /// @notice The JPEG locks. See {applyTraitBoost} for more info.
    mapping(uint256 => JPEGLock) public lockPositions;

    /// @dev Checks if the provided NFT index is valid
    /// @param nftIndex The index to check
    modifier validNFTIndex(uint256 nftIndex) {
        //The standard OZ ERC721 implementation of ownerOf reverts on a non existing nft isntead of returning address(0)
        if (nftContract.ownerOf(nftIndex) == address(0))
            revert InvalidNFT(nftIndex);
        _;
    }

    struct NFTCategoryInitializer {
        bytes32 hash;
        Rate valueMultiplier;
        uint256[] nfts;
    }

    /// @notice This function is only called once during deployment of the proxy contract. It's not called after upgrades.
    /// @param _stablecoin PETH address
    /// @param _nftContract The NFT contrat address. It could also be the address of an helper contract
    /// if the target NFT isn't an ERC721 (CryptoPunks as an example)
    /// @param _floorOracle Chainlink floor oracle address
    /// @param _typeInitializers Used to initialize NFT categories with their value and NFT indexes.
    /// Floor NFT shouldn't be initialized this way
    /// @param _settings Initial settings used by the contract
    function initialize(
        IStableCoin _stablecoin,
        IERC20Upgradeable _jpeg,
        IERC721Upgradeable _nftContract,
        IAggregatorV3Interface _floorOracle,
        NFTCategoryInitializer[] calldata _typeInitializers,
        IJPEGCardsCigStaking _cigStaking,
        VaultSettings calldata _settings
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DAO_ROLE, msg.sender);
        _setRoleAdmin(LIQUIDATOR_ROLE, DAO_ROLE);
        _setRoleAdmin(SETTER_ROLE, DAO_ROLE);
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);

        _validateRateBelowOne(_settings.debtInterestApr);
        _validateRateBelowOne(_settings.creditLimitRate);
        _validateRateBelowOne(_settings.liquidationLimitRate);
        _validateRateBelowOne(_settings.cigStakedCreditLimitRate);
        _validateRateBelowOne(_settings.cigStakedLiquidationLimitRate);
        _validateRateBelowOne(_settings.valueIncreaseLockRate);
        _validateRateBelowOne(_settings.organizationFeeRate);
        _validateRateBelowOne(_settings.insurancePurchaseRate);
        _validateRateBelowOne(_settings.insuranceLiquidationPenaltyRate);

        if (
            !_greaterThan(
                _settings.liquidationLimitRate,
                _settings.creditLimitRate
            )
        ) revert InvalidRate(_settings.liquidationLimitRate);

        if (
            !_greaterThan(
                _settings.cigStakedLiquidationLimitRate,
                _settings.cigStakedCreditLimitRate
            )
        ) revert InvalidRate(_settings.cigStakedLiquidationLimitRate);

        if (
            !_greaterThan(
                _settings.cigStakedCreditLimitRate,
                _settings.creditLimitRate
            )
        ) revert InvalidRate(_settings.cigStakedCreditLimitRate);

        if (
            !_greaterThan(
                _settings.cigStakedLiquidationLimitRate,
                _settings.liquidationLimitRate
            )
        ) revert InvalidRate(_settings.cigStakedLiquidationLimitRate);

        stablecoin = _stablecoin;
        jpeg = _jpeg;
        floorOracle = _floorOracle;
        cigStaking = _cigStaking;
        nftContract = _nftContract;

        settings = _settings;

        //initializing the categories
        for (uint256 i; i < _typeInitializers.length; ++i) {
            NFTCategoryInitializer memory initializer = _typeInitializers[i];
            if (initializer.hash == bytes32(0))
                revert InvalidNFTType(initializer.hash);
            _validateRateAboveOne(initializer.valueMultiplier);
            nftTypeValueMultiplier[initializer.hash] = initializer
                .valueMultiplier;
            for (uint256 j; j < initializer.nfts.length; j++) {
                nftTypes[initializer.nfts[j]] = initializer.hash;
            }
        }
    }

    /// @dev Function called by the {ProxyAdmin} contract during the upgrade process.
    /// Only called on existing vaults where the `initialize` function has already been called.
    /// It won't be called in new deployments.
    /// Sets the JPEG token address, migrates overridden floor to the new `overriddenFloorValueETH` variable,
    /// clears the `unused1` mapping and sets `DAO_ROLE` as admin for the `SETTER_ROLE`.
    function finalizeUpgrade(IERC20Upgradeable _jpeg, bytes32[] memory _toClear)
        external
    {
        require(address(jpeg) == address(0)); //already finalized
        if (address(_jpeg) == address(0)) revert ZeroAddress();

        _setRoleAdmin(SETTER_ROLE, DAO_ROLE);

        jpeg = _jpeg;
        overriddenFloorValueETH = unused1[bytes32(0)];

        for (uint256 i; i < _toClear.length; ++i) {
            delete unused1[_toClear[i]];
        }
    }

    /// @notice Returns the number of open positions
    /// @return The number of open positions
    function totalPositions() external view returns (uint256) {
        return positionIndexes.length();
    }

    /// @notice Returns all open position NFT indexes
    /// @return The open position NFT indexes
    function openPositionsIndexes() external view returns (uint256[] memory) {
        return positionIndexes.values();
    }

    /// @param _nftIndex The NFT to return the value of
    /// @return The value in ETH of the NFT at index `_nftIndex`, with 18 decimals.
    function getNFTValueETH(uint256 _nftIndex) public view returns (uint256) {
        uint256 floor = getFloorETH();

        bytes32 nftType = nftTypes[_nftIndex];
        if (
            nftType != bytes32(0) &&
            lockPositions[_nftIndex].unlockAt > block.timestamp
        ) {
            Rate memory multiplier = nftTypeValueMultiplier[nftType];
            return (floor * multiplier.numerator) / multiplier.denominator;
        } else return floor;
    }

    /// @param _nftType The NFT type to calculate the JPEG lock amount for
    /// @param _jpegPrice The JPEG price in ETH (18 decimals)
    /// @return The JPEG to lock for the specified `_nftType`
    function calculateJPEGToLock(bytes32 _nftType, uint256 _jpegPrice)
        public
        view
        returns (uint256)
    {
        Rate memory multiplier = nftTypeValueMultiplier[_nftType];

        if (multiplier.numerator == 0 || multiplier.denominator == 0) return 0;

        uint256 floorETH = getFloorETH();
        return
            (((floorETH * multiplier.numerator) /
                multiplier.denominator -
                floorETH) *
                1 ether *
                settings.valueIncreaseLockRate.numerator *
                settings.creditLimitRate.numerator) /
            settings.valueIncreaseLockRate.denominator /
            settings.creditLimitRate.denominator /
            _jpegPrice;
    }

    /// @param _nftIndex The NFT to return the credit limit of
    /// @return The PETH credit limit of the NFT at index `_nftIndex`.
    function getCreditLimit(uint256 _nftIndex) external view returns (uint256) {
        return _getCreditLimit(positionOwner[_nftIndex], _nftIndex);
    }

    /// @param _nftIndex The NFT to return the liquidation limit of
    /// @return The PETH liquidation limit of the NFT at index `_nftIndex`.
    function getLiquidationLimit(uint256 _nftIndex)
        public
        view
        returns (uint256)
    {
        return _getLiquidationLimit(positionOwner[_nftIndex], _nftIndex);
    }

    /// @param _nftIndex The NFT to check
    /// @return Whether the NFT at index `_nftIndex` is liquidatable.
    function isLiquidatable(uint256 _nftIndex) external view returns (bool) {
        Position storage position = positions[_nftIndex];
        if (position.borrowType == BorrowType.NOT_CONFIRMED) return false;
        if (position.liquidatedAt > 0) return false;

        uint256 principal = position.debtPrincipal;
        return
            principal + getDebtInterest(_nftIndex) >=
            getLiquidationLimit(_nftIndex);
    }

    /// @param _nftIndex The NFT to check
    /// @return The PETH debt interest accumulated by the NFT at index `_nftIndex`.
    function getDebtInterest(uint256 _nftIndex) public view returns (uint256) {
        Position storage position = positions[_nftIndex];
        uint256 principal = position.debtPrincipal;
        uint256 debt = position.liquidatedAt != 0
            ? position.debtAmountForRepurchase
            : _calculateDebt(
                totalDebtAmount + _calculateAdditionalInterest(),
                position.debtPortion,
                totalDebtPortion
            );

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal if no time has elapsed in between the first borrow
        //and the _calculateDebt call.
        if (principal > debt) debt = principal;

        unchecked {
            return debt - principal;
        }
    }

    /// @return The floor value for the collection, in ETH.
    function getFloorETH() public view returns (uint256) {
        if (daoFloorOverride) return overriddenFloorValueETH;
        else
            return
                _normalizeAggregatorAnswer(
                    useFallbackOracle ? fallbackOracle : floorOracle
                );
    }

    /// @dev The {accrue} function updates the contract's state by calculating
    /// the additional interest accrued since the last state update
    function accrue() public {
        uint256 additionalInterest = _calculateAdditionalInterest();

        totalDebtAccruedAt = block.timestamp;

        totalDebtAmount += additionalInterest;
        totalFeeCollected += additionalInterest;
    }

    /// @notice Allows to execute multiple actions in a single transaction.
    /// @param _actions The actions to execute.
    /// @param _datas The abi encoded parameters for the actions to execute.
    function doActions(uint8[] calldata _actions, bytes[] calldata _datas)
        external
        nonReentrant
    {
        if (_actions.length != _datas.length) revert();
        bool accrueCalled;
        for (uint256 i; i < _actions.length; ++i) {
            uint8 action = _actions[i];
            if (!accrueCalled && action < 100) {
                accrue();
                accrueCalled = true;
            }

            if (action == ACTION_BORROW) {
                (uint256 nftIndex, uint256 amount, bool useInsurance) = abi
                    .decode(_datas[i], (uint256, uint256, bool));
                _borrow(nftIndex, amount, useInsurance);
            } else if (action == ACTION_REPAY) {
                (uint256 nftIndex, uint256 amount) = abi.decode(
                    _datas[i],
                    (uint256, uint256)
                );
                _repay(nftIndex, amount);
            } else if (action == ACTION_CLOSE_POSITION) {
                uint256 nftIndex = abi.decode(_datas[i], (uint256));
                _closePosition(nftIndex);
            } else if (action == ACTION_LIQUIDATE) {
                (uint256 nftIndex, address recipient) = abi.decode(
                    _datas[i],
                    (uint256, address)
                );
                _liquidate(nftIndex, recipient);
            } else if (action == ACTION_REPURCHASE) {
                uint256 nftIndex = abi.decode(_datas[i], (uint256));
                _repurchase(nftIndex);
            } else if (action == ACTION_CLAIM_NFT) {
                (uint256 nftIndex, address recipient) = abi.decode(
                    _datas[i],
                    (uint256, address)
                );
                _claimExpiredInsuranceNFT(nftIndex, recipient);
            } else if (action == ACTION_TRAIT_BOOST) {
                (uint256 nftIndex, uint256 unlockAt) = abi.decode(
                    _datas[i],
                    (uint256, uint256)
                );
                _applyTraitBoost(nftIndex, unlockAt);
            } else if (action == ACTION_UNLOCK_JPEG) {
                uint256 nftIndex = abi.decode(_datas[i], (uint256));
                _unlockJPEG(nftIndex);
            } else {
                revert UnknownAction(action);
            }
        }
    }

    /// @notice Allows users to lock JPEG tokens to unlock the trait boost for a single non floor NFT.
    /// The trait boost is a multiplicative value increase relative to the collection's floor.
    /// The value increase depends on the NFT's traits and it's set by the DAO.
    /// The ETH value of the JPEG to lock is calculated by applying the `valueIncreaseLockRate` rate to the NFT's new credit limit.
    /// The unlock time is set by the user and has to be greater than `block.timestamp` and the previous unlock time.
    /// After the lock expires, the boost is revoked and the NFT's value goes back to floor.
    /// If a boosted position is closed or liquidated, the JPEG remains locked and the boost will still be applied in case the NFT
    /// is deposited again, even in case of a different owner. The locked JPEG will only be claimable by the original lock creator
    /// once the lock expires. If the lock is renewed by the new owner, the JPEG from the previous lock will be sent back to the original
    /// lock creator.
    /// @dev emits a {JPEGLocked} event
    /// @param _nftIndex The index of the NFT to boost (has to be a non floor NFT)
    /// @param _unlockAt The lock expiration time.
    function applyTraitBoost(uint256 _nftIndex, uint256 _unlockAt)
        external
        nonReentrant
    {
        _applyTraitBoost(_nftIndex, _unlockAt);
    }

    /// @notice Allows lock creators to unlock the JPEG associated to the NFT at index `_nftIndex`, provided the lock expired.
    /// @dev emits a {JPEGUnlocked} event
    /// @param _nftIndex The index of the NFT holding the lock.
    function unlockJPEG(uint256 _nftIndex) external nonReentrant {
        _unlockJPEG(_nftIndex);
    }

    /// @notice Allows users to open positions and borrow using an NFT
    /// @dev emits a {Borrowed} event
    /// @param _nftIndex The index of the NFT to be used as collateral
    /// @param _amount The amount of PETH to be borrowed. Note that the user will receive less than the amount requested,
    /// the borrow fee and insurance automatically get removed from the amount borrowed
    /// @param _useInsurance Whereter to open an insured position. In case the position has already been opened previously,
    /// this parameter needs to match the previous insurance mode. To change insurance mode, a user needs to close and reopen the position
    function borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) external nonReentrant {
        accrue();
        _borrow(_nftIndex, _amount, _useInsurance);
    }

    /// @notice Allows users to repay a portion/all of their debt. Note that since interest increases every second,
    /// a user wanting to repay all of their debt should repay for an amount greater than their current debt to account for the
    /// additional interest while the repay transaction is pending, the contract will only take what's necessary to repay all the debt
    /// @dev Emits a {Repaid} event
    /// @param _nftIndex The NFT used as collateral for the position
    /// @param _amount The amount of debt to repay. If greater than the position's outstanding debt, only the amount necessary to repay all the debt will be taken
    function repay(uint256 _nftIndex, uint256 _amount) external nonReentrant {
        accrue();
        _repay(_nftIndex, _amount);
    }

    /// @notice Allows a user to close a position and get their collateral back, if the position's outstanding debt is 0
    /// @dev Emits a {PositionClosed} event
    /// @param _nftIndex The index of the NFT used as collateral
    function closePosition(uint256 _nftIndex) external nonReentrant {
        accrue();
        _closePosition(_nftIndex);
    }

    /// @notice Allows members of the `LIQUIDATOR_ROLE` to liquidate a position. Positions can only be liquidated
    /// once their debt amount exceeds the minimum liquidation debt to collateral value rate.
    /// In order to liquidate a position, the liquidator needs to repay the user's outstanding debt.
    /// If the position is not insured, it's closed immediately and the collateral is sent to `_recipient`.
    /// If the position is insured, the position remains open (interest doesn't increase) and the owner of the position has a certain amount of time
    /// (`insuranceRepurchaseTimeLimit`) to fully repay the liquidator and pay an additional liquidation fee (`insuranceLiquidationPenaltyRate`), if this
    /// is done in time the user gets back their collateral and their position is automatically closed. If the user doesn't repurchase their collateral
    /// before the time limit passes, the liquidator can claim the liquidated NFT and the position is closed
    /// @dev Emits a {Liquidated} event
    /// @param _nftIndex The NFT to liquidate
    /// @param _recipient The address to send the NFT to
    function liquidate(uint256 _nftIndex, address _recipient)
        external
        nonReentrant
    {
        accrue();
        _liquidate(_nftIndex, _recipient);
    }

    /// @notice Allows liquidated users who purchased insurance to repurchase their collateral within the time limit
    /// defined with the `insuranceRepurchaseTimeLimit`. The user needs to pay the liquidator the total amount of debt
    /// the position had at the time of liquidation, plus an insurance liquidation fee defined with `insuranceLiquidationPenaltyRate`
    /// @dev Emits a {Repurchased} event
    /// @param _nftIndex The NFT to repurchase
    function repurchase(uint256 _nftIndex) external nonReentrant {
        _repurchase(_nftIndex);
    }

    /// @notice Allows the liquidator who liquidated the insured position with NFT at index `_nftIndex` to claim the position's collateral
    /// after the time period defined with `insuranceRepurchaseTimeLimit` has expired and the position owner has not repurchased the collateral.
    /// @dev Emits an {InsuranceExpired} event
    /// @param _nftIndex The NFT to claim
    /// @param _recipient The address to send the NFT to
    function claimExpiredInsuranceNFT(uint256 _nftIndex, address _recipient)
        external
        nonReentrant
    {
        _claimExpiredInsuranceNFT(_nftIndex, _recipient);
    }

    /// @notice Allows the DAO to collect interest and fees before they are repaid
    function collect() external nonReentrant onlyRole(DAO_ROLE) {
        accrue();
        stablecoin.mint(msg.sender, totalFeeCollected);
        totalFeeCollected = 0;
    }

    /// @notice Allows the setter contract to change fields in the `VaultSettings` struct.
    /// @dev Validation and single field setting is handled by an external contract with the
    /// `SETTER_ROLE`. This was done to reduce the contract's size.
    function setSettings(VaultSettings calldata _settings)
        external
        onlyRole(SETTER_ROLE)
    {
        settings = _settings;
    }

    /// @notice Allows the DAO to toggle the fallback oracle
    /// @param _useFallback Whether to use the fallback oracle
    function toggleFallbackOracle(bool _useFallback)
        external
        onlyRole(DAO_ROLE)
    {
        require(address(fallbackOracle) != address(0));
        useFallbackOracle = _useFallback;
    }

    /// @notice Allows the DAO to bypass the floor oracle and override the NFT floor value
    /// @param _newFloor The new floor
    function overrideFloor(uint256 _newFloor) external onlyRole(DAO_ROLE) {
        if (_newFloor == 0) revert InvalidAmount(_newFloor);
        overriddenFloorValueETH = _newFloor;
        daoFloorOverride = true;

        emit DaoFloorChanged(_newFloor);
    }

    /// @notice Allows the DAO to stop overriding floor
    function disableFloorOverride() external onlyRole(DAO_ROLE) {
        daoFloorOverride = false;
    }

    /// @notice Allows the DAO to add an NFT to a specific price category
    /// @param _nftIndexes The indexes to add to the category
    /// @param _type The category hash
    function setNFTType(uint256[] calldata _nftIndexes, bytes32 _type)
        external
        onlyRole(DAO_ROLE)
    {
        if (_type != bytes32(0) && nftTypeValueMultiplier[_type].numerator == 0)
            revert InvalidNFTType(_type);

        for (uint256 i; i < _nftIndexes.length; ++i) {
            nftTypes[_nftIndexes[i]] = _type;
        }
    }

    /// @notice Allows the DAO to change the multiplier of an NFT category
    /// @param _type The category hash
    /// @param _multiplier The new multiplier
    function setNFTTypeMultiplier(bytes32 _type, Rate calldata _multiplier)
        external
        onlyRole(DAO_ROLE)
    {
        if (_type == bytes32(0)) revert InvalidNFTType(_type);
        _validateRateAboveOne(_multiplier);
        nftTypeValueMultiplier[_type] = _multiplier;
    }

    /// @notice Allows the DAO to set the JPEG oracle
    /// @param _oracle new oracle address
    function setjpegOracle(IUniswapV2Oracle _oracle)
        external
        onlyRole(DAO_ROLE)
    {
        if (address(_oracle) == address(0)) revert ZeroAddress();

        jpegOracle = _oracle;
    }

    /// @notice Allows the DAO to change fallback oracle
    /// @param _fallback new fallback address
    function setFallbackOracle(IAggregatorV3Interface _fallback)
        external
        onlyRole(DAO_ROLE)
    {
        if (address(_fallback) == address(0)) revert ZeroAddress();

        fallbackOracle = _fallback;
    }

    /// @notice Allows the DAO to change the minimum amount of JPEG to lock to unlock the trait boost
    function setMinJPEGToLock(uint256 _newAmount) external onlyRole(DAO_ROLE) {
        if (_newAmount == 0) revert InvalidAmount(_newAmount);

        minJPEGToLock = _newAmount;
    }

    /// @dev See {applyTraitBoost}
    function _applyTraitBoost(uint256 _nftIndex, uint256 _unlockAt)
        internal
        validNFTIndex(_nftIndex)
    {
        bytes32 nftType = nftTypes[_nftIndex];
        if (nftType == bytes32(0)) revert InvalidNFTType(nftType);

        JPEGLock storage jpegLock = lockPositions[_nftIndex];
        if (block.timestamp >= _unlockAt || jpegLock.unlockAt >= _unlockAt)
            revert InvalidUnlockTime(_unlockAt);

        uint256 jpegToLock = calculateJPEGToLock(nftType, _jpegPriceETH());

        if (minJPEGToLock >= jpegToLock) revert InvalidNFTType(nftType);

        uint256 previousLockValue = jpegLock.lockedValue;
        address previousOwner = jpegLock.owner;

        jpegLock.lockedValue = jpegToLock;
        jpegLock.unlockAt = _unlockAt;
        jpegLock.owner = msg.sender;

        if (previousOwner == msg.sender) {
            if (jpegToLock > previousLockValue)
                jpeg.safeTransferFrom(
                    msg.sender,
                    address(this),
                    jpegToLock - previousLockValue
                );
            else if (previousLockValue > jpegToLock)
                jpeg.safeTransfer(msg.sender, previousLockValue - jpegToLock);
        } else {
            if (previousLockValue > 0)
                jpeg.safeTransfer(previousOwner, previousLockValue);
            jpeg.safeTransferFrom(msg.sender, address(this), jpegToLock);
        }

        emit JPEGLocked(msg.sender, _nftIndex, jpegToLock, _unlockAt);
    }

    /// @dev See {unlockJPEG}
    function _unlockJPEG(uint256 _nftIndex) internal validNFTIndex(_nftIndex) {
        JPEGLock memory jpegLock = lockPositions[_nftIndex];
        if (jpegLock.owner != msg.sender) revert Unauthorized();

        if (block.timestamp < jpegLock.unlockAt) revert Unauthorized();

        delete lockPositions[_nftIndex];

        jpeg.safeTransfer(msg.sender, jpegLock.lockedValue);

        emit JPEGUnlocked(msg.sender, _nftIndex, jpegLock.lockedValue);
    }

    /// @dev Opens a position
    /// Emits a {PositionOpened} event
    /// @param _owner The owner of the position to open
    /// @param _nftIndex The NFT used as collateral for the position
    function _openPosition(address _owner, uint256 _nftIndex) internal {
        positionOwner[_nftIndex] = _owner;
        positionIndexes.add(_nftIndex);

        nftContract.transferFrom(_owner, address(this), _nftIndex);

        emit PositionOpened(_owner, _nftIndex);
    }

    /// @dev See {borrow}
    function _borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) internal validNFTIndex(_nftIndex) {
        address owner = positionOwner[_nftIndex];
        if (owner != msg.sender && owner != address(0)) revert Unauthorized();

        if (_amount == 0) revert InvalidAmount(_amount);

        if (totalDebtAmount + _amount > settings.borrowAmountCap)
            revert DebtCapReached();

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt != 0) revert PositionLiquidated(_nftIndex);

        BorrowType borrowType = position.borrowType;
        BorrowType targetBorrowType = _useInsurance
            ? BorrowType.USE_INSURANCE
            : BorrowType.NON_INSURANCE;

        if (borrowType == BorrowType.NOT_CONFIRMED)
            position.borrowType = targetBorrowType;
        else if (borrowType != targetBorrowType) revert InvalidInsuranceMode();

        uint256 creditLimit = _getCreditLimit(msg.sender, _nftIndex);
        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount + _amount > creditLimit) revert InvalidAmount(_amount);

        //calculate the borrow fee
        uint256 organizationFee = (_amount *
            settings.organizationFeeRate.numerator) /
            settings.organizationFeeRate.denominator;

        uint256 feeAmount = organizationFee;
        //if the position is insured, calculate the insurance fee
        if (targetBorrowType == BorrowType.USE_INSURANCE) {
            feeAmount +=
                (_amount * settings.insurancePurchaseRate.numerator) /
                settings.insurancePurchaseRate.denominator;
        }
        totalFeeCollected += feeAmount;

        uint256 debtPortion = totalDebtPortion;
        // update debt portion
        if (debtPortion == 0) {
            totalDebtPortion = _amount;
            position.debtPortion = _amount;
        } else {
            uint256 plusPortion = (debtPortion * _amount) / totalDebtAmount;
            totalDebtPortion = debtPortion + plusPortion;
            position.debtPortion += plusPortion;
        }
        position.debtPrincipal += _amount;
        totalDebtAmount += _amount;

        if (positionOwner[_nftIndex] == address(0)) {
            _openPosition(msg.sender, _nftIndex);
        }

        //subtract the fee from the amount borrowed
        stablecoin.mint(msg.sender, _amount - feeAmount);

        emit Borrowed(msg.sender, _nftIndex, _amount);
    }

    /// @dev See {repay}
    function _repay(uint256 _nftIndex, uint256 _amount)
        internal
        validNFTIndex(_nftIndex)
    {
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();

        if (_amount == 0) revert InvalidAmount(_amount);

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt > 0) revert PositionLiquidated(_nftIndex);

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount == 0) revert NoDebt();

        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = debtAmount - debtPrincipal;

        _amount = _amount > debtAmount ? debtAmount : _amount;

        // burn all payment, the interest is sent to the DAO using the {collect} function
        stablecoin.burnFrom(msg.sender, _amount);

        uint256 paidPrincipal;

        unchecked {
            paidPrincipal = _amount > debtInterest ? _amount - debtInterest : 0;
        }

        uint256 totalPortion = totalDebtPortion;
        uint256 totalDebt = totalDebtAmount;
        uint256 minusPortion = paidPrincipal == debtPrincipal
            ? position.debtPortion
            : (totalPortion * _amount) / totalDebt;

        totalDebtPortion = totalPortion - minusPortion;
        position.debtPortion -= minusPortion;
        position.debtPrincipal -= paidPrincipal;
        totalDebtAmount = totalDebt - _amount;

        emit Repaid(msg.sender, _nftIndex, _amount);
    }

    /// @dev See {closePosition}
    function _closePosition(uint256 _nftIndex)
        internal
        validNFTIndex(_nftIndex)
    {
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();
        if (positions[_nftIndex].liquidatedAt > 0)
            revert PositionLiquidated(_nftIndex);
        uint256 debt = _getDebtAmount(_nftIndex);
        if (debt > 0) revert NonZeroDebt(debt);

        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        // transfer nft back to owner if nft was deposited
        if (nftContract.ownerOf(_nftIndex) == address(this)) {
            nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);
        }

        emit PositionClosed(msg.sender, _nftIndex);
    }

    /// @dev See {liquidate}
    function _liquidate(uint256 _nftIndex, address _recipient)
        internal
        onlyRole(LIQUIDATOR_ROLE)
        validNFTIndex(_nftIndex)
    {
        address posOwner = positionOwner[_nftIndex];
        if (posOwner == address(0)) revert InvalidPosition(_nftIndex);

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt > 0) revert PositionLiquidated(_nftIndex);

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount < _getLiquidationLimit(posOwner, _nftIndex))
            revert InvalidPosition(_nftIndex);

        // burn all payment
        stablecoin.burnFrom(msg.sender, debtAmount);

        // update debt portion
        totalDebtPortion -= position.debtPortion;
        totalDebtAmount -= debtAmount;
        position.debtPortion = 0;

        bool insured = position.borrowType == BorrowType.USE_INSURANCE;
        if (insured) {
            position.debtAmountForRepurchase = debtAmount;
            position.liquidatedAt = block.timestamp;
            position.liquidator = msg.sender;
        } else {
            // transfer nft to liquidator
            positionOwner[_nftIndex] = address(0);
            delete positions[_nftIndex];
            positionIndexes.remove(_nftIndex);
            nftContract.transferFrom(address(this), _recipient, _nftIndex);
        }

        emit Liquidated(msg.sender, posOwner, _nftIndex, insured);
    }

    /// @dev See {repurchase}
    function _repurchase(uint256 _nftIndex) internal validNFTIndex(_nftIndex) {
        Position memory position = positions[_nftIndex];
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();
        if (position.liquidatedAt == 0) revert InvalidPosition(_nftIndex);
        if (position.borrowType != BorrowType.USE_INSURANCE)
            revert InvalidPosition(_nftIndex);
        if (
            block.timestamp >=
            position.liquidatedAt + settings.insuranceRepurchaseTimeLimit
        ) revert PositionInsuranceExpired(_nftIndex);

        uint256 debtAmount = position.debtAmountForRepurchase;
        uint256 penalty = (debtAmount *
            settings.insuranceLiquidationPenaltyRate.numerator) /
            settings.insuranceLiquidationPenaltyRate.denominator;

        // transfer nft to user
        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        // transfer payment to liquidator
        stablecoin.safeTransferFrom(
            msg.sender,
            position.liquidator,
            debtAmount + penalty
        );

        nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);

        emit Repurchased(msg.sender, _nftIndex);
    }

    /// @dev See {claimExpiredInsuranceNFT}
    function _claimExpiredInsuranceNFT(uint256 _nftIndex, address _recipient)
        internal
        validNFTIndex(_nftIndex)
    {
        if (_recipient == address(0)) revert ZeroAddress();
        Position memory position = positions[_nftIndex];
        address owner = positionOwner[_nftIndex];
        if (owner == address(0)) revert InvalidPosition(_nftIndex);
        if (position.liquidatedAt == 0) revert InvalidPosition(_nftIndex);
        if (
            position.liquidatedAt + settings.insuranceRepurchaseTimeLimit >
            block.timestamp
        ) revert PositionInsuranceNotExpired(_nftIndex);
        if (position.liquidator != msg.sender) revert Unauthorized();

        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        nftContract.transferFrom(address(this), _recipient, _nftIndex);

        emit InsuranceExpired(owner, _nftIndex);
    }

    /// @dev Returns the credit limit of an NFT
    /// @param _nftIndex The NFT to return credit limit of
    /// @return The NFT credit limit
    function _getCreditLimit(address user, uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        uint256 value = getNFTValueETH(_nftIndex);
        if (cigStaking.isUserStaking(user)) {
            return
                (value * settings.cigStakedCreditLimitRate.numerator) /
                settings.cigStakedCreditLimitRate.denominator;
        }
        return
            (value * settings.creditLimitRate.numerator) /
            settings.creditLimitRate.denominator;
    }

    /// @dev Returns the minimum amount of debt necessary to liquidate an NFT
    /// @param _nftIndex The index of the NFT
    /// @return The minimum amount of debt to liquidate the NFT
    function _getLiquidationLimit(address user, uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        uint256 value = getNFTValueETH(_nftIndex);
        if (cigStaking.isUserStaking(user)) {
            return
                (value * settings.cigStakedLiquidationLimitRate.numerator) /
                settings.cigStakedLiquidationLimitRate.denominator;
        }
        return
            (value * settings.liquidationLimitRate.numerator) /
            settings.liquidationLimitRate.denominator;
    }

    /// @dev Calculates current outstanding debt of an NFT
    /// @param _nftIndex The NFT to calculate the outstanding debt of
    /// @return The outstanding debt value
    function _getDebtAmount(uint256 _nftIndex) internal view returns (uint256) {
        uint256 calculatedDebt = _calculateDebt(
            totalDebtAmount,
            positions[_nftIndex].debtPortion,
            totalDebtPortion
        );

        uint256 principal = positions[_nftIndex].debtPrincipal;

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal when the accrue() function isn't called
        //in between the first borrow and the _calculateDebt call.
        return principal > calculatedDebt ? principal : calculatedDebt;
    }

    /// @dev Calculates the total debt of a position given the global debt, the user's portion of the debt and the total user portions
    /// @param total The global outstanding debt
    /// @param userPortion The user's portion of debt
    /// @param totalPortion The total user portions of debt
    /// @return The outstanding debt of the position
    function _calculateDebt(
        uint256 total,
        uint256 userPortion,
        uint256 totalPortion
    ) internal pure returns (uint256) {
        return totalPortion == 0 ? 0 : (total * userPortion) / totalPortion;
    }

    /// @dev Calculates the additional global interest since last time the contract's state was updated by calling {accrue}
    /// @return The additional interest value
    function _calculateAdditionalInterest() internal view returns (uint256) {
        // Number of seconds since {accrue} was called
        uint256 elapsedTime = block.timestamp - totalDebtAccruedAt;
        if (elapsedTime == 0) {
            return 0;
        }

        uint256 totalDebt = totalDebtAmount;
        if (totalDebt == 0) {
            return 0;
        }

        // Accrue interest
        return
            (elapsedTime * totalDebt * settings.debtInterestApr.numerator) /
            settings.debtInterestApr.denominator /
            365 days;
    }

    /// @dev Returns the current JPEG price in ETH
    /// @return result The current JPEG price, 18 decimals
    function _jpegPriceETH() internal returns (uint256 result) {
        IUniswapV2Oracle oracle = jpegOracle;
        if (address(oracle) == address(0)) revert NoOracleSet();
        result = oracle.consultAndUpdateIfNecessary(address(jpeg), 1 ether);
        if (result == 0) revert InvalidOracleResults();
    }

    /// @dev Fetches and converts to 18 decimals precision the latest answer of a Chainlink aggregator
    /// @param aggregator The aggregator to fetch the answer from
    /// @return The latest aggregator answer, normalized
    function _normalizeAggregatorAnswer(IAggregatorV3Interface aggregator)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , uint256 timestamp, ) = aggregator.latestRoundData();

        if (answer == 0 || timestamp == 0) revert InvalidOracleResults();

        uint8 decimals = aggregator.decimals();

        unchecked {
            //converts the answer to have 18 decimals
            return
                decimals > 18
                    ? uint256(answer) / 10**(decimals - 18)
                    : uint256(answer) * 10**(18 - decimals);
        }
    }

    /// @dev Checks if `r1` is greater than `r2`.
    function _greaterThan(Rate memory _r1, Rate memory _r2)
        internal
        pure
        returns (bool)
    {
        return
            _r1.numerator * _r2.denominator > _r2.numerator * _r1.denominator;
    }

    /// @dev Validates a rate. The denominator must be greater than zero and greater than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateBelowOne(Rate memory _rate) internal pure {
        if (_rate.denominator == 0 || _rate.denominator < _rate.numerator)
            revert InvalidRate(_rate);
    }

    /// @dev Validates a rate. The denominator must be greater than zero and less than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateAboveOne(Rate memory _rate) internal pure {
        if (_rate.denominator == 0 || _rate.numerator < _rate.denominator)
            revert InvalidRate(_rate);
    }
}