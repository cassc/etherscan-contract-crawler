// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../utils/RateLib.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IUniswapV2Oracle.sol";
import "../interfaces/IJPEGOraclesAggregator.sol";
import "../interfaces/IJPEGCardsCigStaking.sol";

contract NFTValueProvider is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using RateLib for RateLib.Rate;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidNFTType(bytes32 nftType);
    error InvalidAmount(uint256 amount);
    error LockExists(uint256 index);
    error Unauthorized();
    error ZeroAddress();
    error InvalidLength();

    event DaoFloorChanged(uint256 newFloor);

    event TraitBoost(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );

    event LTVBoost(
        address indexed owner,
        uint256 indexed index,
        uint256 amount,
        uint128 rateIncreaseBps
    );

    event TraitBoostReleaseQueued(
        address indexed owner,
        uint256 indexed index,
        uint256 unlockTime
    );

    event LTVBoostReleaseQueued(
        address indexed owner,
        uint256 indexed index,
        uint256 unlockTime
    );

    event TraitBoostReleaseCancelled(
        address indexed owner,
        uint256 indexed index
    );

    event LTVBoostReleaseCancelled(
        address indexed owner,
        uint256 indexed index
    );

    event TraitBoostUnlock(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );

    event LTVBoostUnlock(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );

    struct JPEGLock {
        address owner;
        uint256 unlockAt;
        uint256 lockedValue;
    }

    /// @notice The JPEG floor oracles aggregator
    IJPEGOraclesAggregator public aggregator;
    /// @notice If true, the floor price won't be fetched using the Chainlink oracle but
    /// a value set by the DAO will be used instead
    bool public daoFloorOverride;
    /// @notice Value of floor set by the DAO. Only used if `daoFloorOverride` is true
    uint256 private overriddenFloorValueETH;

    /// @notice The JPEG token
    IERC20Upgradeable public jpeg;
    /// @notice Value of the JPEG to lock for trait boost based on the NFT value increase
    /// @custom:oz-renamed-from valueIncreaseLockRate
    RateLib.Rate public traitBoostLockRate;
    /// @notice Minimum amount of JPEG to lock for trait boost
    uint256 public minJPEGToLock;

    mapping(uint256 => bytes32) public nftTypes;
    mapping(bytes32 => RateLib.Rate) public nftTypeValueMultiplier;
    /// @custom:oz-renamed-from lockPositions
    mapping(uint256 => JPEGLock) public traitBoostPositions;
    mapping(uint256 => JPEGLock) public ltvBoostPositions;

    RateLib.Rate public baseCreditLimitRate;
    RateLib.Rate public baseLiquidationLimitRate;
    RateLib.Rate public cigStakedRateIncrease;
    /// @custom:oz-renamed-from jpegLockedRateIncrease
    RateLib.Rate public jpegLockedMaxRateIncrease;

    /// @notice Value of the JPEG to lock for ltv boost based on the NFT ltv increase
    RateLib.Rate public ltvBoostLockRate;

    /// @notice JPEGCardsCigStaking, cig stakers get an higher credit limit rate and liquidation limit rate.
    /// Immediately reverts to normal rates if the cig is unstaked.
    IJPEGCardsCigStaking public cigStaking;

    mapping(uint256 => RateLib.Rate) public ltvBoostRateIncreases;

    RateLib.Rate public creditLimitRateCap;
    RateLib.Rate public liquidationLimitRateCap;

    uint256 public lockReleaseDelay;

    /// @notice This function is only called once during deployment of the proxy contract. It's not called after upgrades.
    /// @param _jpeg The JPEG token
    /// @param _aggregator The JPEG floor oracles aggregator
    /// @param _cigStaking The cig staking address
    /// @param _baseCreditLimitRate The base credit limit rate
    /// @param _baseLiquidationLimitRate The base liquidation limit rate
    /// @param _cigStakedRateIncrease The liquidation and credit limit rate increases for users staking a cig in the cigStaking contract
    /// @param _jpegLockedMaxRateIncrease The maximum liquidation and credit limit rate increases for users that locked JPEG for LTV boost
    /// @param _traitBoostLockRate The rate used to calculate the amount of JPEG to lock for trait boost based on the NFT's value increase
    /// @param _ltvBoostLockRate The rate used to calculate the amount of JPEG to lock for LTV boost based on the NFT's credit limit increase
    /// @param _creditLimitRateCap The maximum credit limit rate
    /// @param _liquidationLimitRateCap The maximum liquidation limit rate
    function initialize(
        IERC20Upgradeable _jpeg,
        IJPEGOraclesAggregator _aggregator,
        IJPEGCardsCigStaking _cigStaking,
        RateLib.Rate calldata _baseCreditLimitRate,
        RateLib.Rate calldata _baseLiquidationLimitRate,
        RateLib.Rate calldata _cigStakedRateIncrease,
        RateLib.Rate calldata _jpegLockedMaxRateIncrease,
        RateLib.Rate calldata _traitBoostLockRate,
        RateLib.Rate calldata _ltvBoostLockRate,
        RateLib.Rate calldata _creditLimitRateCap,
        RateLib.Rate calldata _liquidationLimitRateCap,
        uint256 _lockReleaseDelay
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        if (address(_jpeg) == address(0)) revert ZeroAddress();
        if (address(_aggregator) == address(0)) revert ZeroAddress();
        if (address(_cigStaking) == address(0)) revert ZeroAddress();

        _validateRateBelowOne(_baseCreditLimitRate);
        _validateRateBelowOne(_baseLiquidationLimitRate);
        _validateRateBelowOne(_cigStakedRateIncrease);
        _validateRateBelowOne(_jpegLockedMaxRateIncrease);
        _validateRateBelowOne(_traitBoostLockRate);
        _validateRateBelowOne(_ltvBoostLockRate);
        _validateRateBelowOne(_creditLimitRateCap);
        _validateRateBelowOne(_liquidationLimitRateCap);

        if (_baseCreditLimitRate.greaterThan(_creditLimitRateCap))
            revert RateLib.InvalidRate();

        if (_baseLiquidationLimitRate.greaterThan(_liquidationLimitRateCap))
            revert RateLib.InvalidRate();

        if (!_baseLiquidationLimitRate.greaterThan(_baseCreditLimitRate))
            revert RateLib.InvalidRate();

        if (!_liquidationLimitRateCap.greaterThan(_creditLimitRateCap))
            revert RateLib.InvalidRate();

        jpeg = _jpeg;
        aggregator = _aggregator;
        cigStaking = _cigStaking;
        baseCreditLimitRate = _baseCreditLimitRate;
        baseLiquidationLimitRate = _baseLiquidationLimitRate;
        cigStakedRateIncrease = _cigStakedRateIncrease;
        jpegLockedMaxRateIncrease = _jpegLockedMaxRateIncrease;
        traitBoostLockRate = _traitBoostLockRate;
        ltvBoostLockRate = _ltvBoostLockRate;
        creditLimitRateCap = _creditLimitRateCap;
        liquidationLimitRateCap = _liquidationLimitRateCap;
        lockReleaseDelay = _lockReleaseDelay;
        minJPEGToLock = 1 ether;
    }

    function finalizeUpgrade(
        RateLib.Rate memory _creditLimitRateCap,
        RateLib.Rate memory _liquidationLimitRateCap,
        uint256 _lockReleaseDelay
    ) external {
        if (
            creditLimitRateCap.denominator != 0 ||
            liquidationLimitRateCap.denominator != 0 ||
            lockReleaseDelay != 0 ||
            _lockReleaseDelay == 0
        ) revert();

        _validateRateBelowOne(_creditLimitRateCap);
        _validateRateBelowOne(_liquidationLimitRateCap);

        if (!_liquidationLimitRateCap.greaterThan(_creditLimitRateCap))
            revert RateLib.InvalidRate();

        creditLimitRateCap = _creditLimitRateCap;
        liquidationLimitRateCap = _liquidationLimitRateCap;
        lockReleaseDelay = _lockReleaseDelay;
    }

    /// @param _owner The owner of the NFT at index `_nftIndex` (or the owner of the associated position in the vault)
    /// @param _nftIndex The index of the NFT to return the credit limit rate for
    /// @return The credit limit rate for the NFT with index `_nftIndex`
    function getCreditLimitRate(
        address _owner,
        uint256 _nftIndex
    ) public view returns (RateLib.Rate memory) {
        return
            _rateAfterBoosts(
                baseCreditLimitRate,
                creditLimitRateCap,
                _owner,
                _nftIndex
            );
    }

    /// @param _owner The owner of the NFT at index `_nftIndex` (or the owner of the associated position in the vault)
    /// @param _nftIndex The index of the NFT to return the liquidation limit rate for
    /// @return The liquidation limit rate for the NFT with index `_nftIndex`
    function getLiquidationLimitRate(
        address _owner,
        uint256 _nftIndex
    ) public view returns (RateLib.Rate memory) {
        return
            _rateAfterBoosts(
                baseLiquidationLimitRate,
                liquidationLimitRateCap,
                _owner,
                _nftIndex
            );
    }

    /// @param _owner The owner of the NFT at index `_nftIndex` (or the owner of the associated position in the vault)
    /// @param _nftIndex The index of the NFT to return the credit limit for
    /// @return The credit limit for the NFT with index `_nftIndex`, in ETH
    function getCreditLimitETH(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256) {
        RateLib.Rate memory _creditLimitRate = getCreditLimitRate(
            _owner,
            _nftIndex
        );
        return _creditLimitRate.calculate(getNFTValueETH(_nftIndex));
    }

    /// @param _owner The owner of the NFT at index `_nftIndex` (or the owner of the associated position in the vault)
    /// @param _nftIndex The index of the NFT to return the liquidation limit for
    /// @return The liquidation limit for the NFT with index `_nftIndex`, in ETH
    function getLiquidationLimitETH(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256) {
        RateLib.Rate memory _liquidationLimitRate = getLiquidationLimitRate(
            _owner,
            _nftIndex
        );
        return _liquidationLimitRate.calculate(getNFTValueETH(_nftIndex));
    }

    /// @param _nftType The NFT type to calculate the JPEG lock amount for
    /// @param _jpegPrice The JPEG price in ETH (18 decimals)
    /// @return The JPEG to lock for the specified `_nftType`
    function calculateTraitBoostLock(
        bytes32 _nftType,
        uint256 _jpegPrice
    ) public view returns (uint256) {
        return
            _calculateTraitBoostLock(
                traitBoostLockRate,
                _nftType,
                getFloorETH(),
                _jpegPrice
            );
    }

    /// @param _jpegPrice The JPEG price in ETH (18 decimals)
    /// @return The JPEG to lock for the specified `_nftIndex`
    function calculateLTVBoostLock(
        uint256 _jpegPrice,
        uint128 _rateIncreaseBps
    ) external view returns (uint256) {
        if (_rateIncreaseBps >= 10000 || _rateIncreaseBps == 0)
            revert InvalidAmount(_rateIncreaseBps);

        RateLib.Rate memory _rateIncrease = RateLib.Rate(
            _rateIncreaseBps,
            10000
        );
        if (_rateIncrease.greaterThan(jpegLockedMaxRateIncrease))
            revert RateLib.InvalidRate();

        RateLib.Rate memory _creditLimitRate = baseCreditLimitRate;
        return
            _calculateLTVBoostLock(
                _creditLimitRate,
                _creditLimitRate.sum(_rateIncrease),
                ltvBoostLockRate,
                getFloorETH(),
                _jpegPrice
            );
    }

    /// @return The floor value for the collection, in ETH.
    function getFloorETH() public view returns (uint256) {
        if (daoFloorOverride) return overriddenFloorValueETH;
        else return aggregator.getFloorETH();
    }

    /// @param _nftIndex The NFT to return the value of
    /// @return The value in ETH of the NFT at index `_nftIndex`, with 18 decimals.
    function getNFTValueETH(uint256 _nftIndex) public view returns (uint256) {
        uint256 _floor = getFloorETH();

        bytes32 _nftType = nftTypes[_nftIndex];
        if (
            _nftType != bytes32(0) &&
            traitBoostPositions[_nftIndex].owner != address(0)
        ) {
            uint256 _unlockAt = traitBoostPositions[_nftIndex].unlockAt;
            if (_unlockAt == 0 || _unlockAt > block.timestamp)
                return nftTypeValueMultiplier[_nftType].calculate(_floor);
        }
        return _floor;
    }

    /// @notice Allows users to lock JPEG tokens to unlock the trait boost for a single non floor NFT.
    /// The trait boost is a multiplicative value increase relative to the collection's floor.
    /// The value increase depends on the NFT's traits and it's set by the DAO.
    /// The ETH value of the JPEG to lock is calculated by applying the `traitBoostLockRate` rate to the NFT's new credit limit.
    /// The boost can be disabled and the JPEG can be released by calling {queueTraitBoostRelease}.
    /// If a boosted position is closed or liquidated, the JPEG remains locked and the boost will still be applied in case the NFT
    /// is deposited again, even in case of a different owner. The locked JPEG will only be claimable by the original lock creator
    /// once the lock expires. If the lock is renewed by the new owner, the JPEG from the previous lock will be sent back to the original
    /// lock creator. Locks can't be overridden while active.
    /// @dev emits multiple {TraitBoostLock} events
    /// @param _nftIndexes The indexes of the non floor NFTs to boost
    function applyTraitBoost(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _applyTraitBoost(_nftIndexes);
    }

    /// @notice Allows users to lock JPEG tokens to unlock the LTV boost for a single NFT.
    /// The LTV boost is an increase of an NFT's credit and liquidation limit rates.
    /// The increase rate is specified by the user, capped at `jpegLockedMaxRateIncrease`.
    /// LTV locks can be overridden by the lock owner without releasing them, provided that the specified rate increase is greater than the previous one. No JPEG is refunded in the process.
    /// The ETH value of the JPEG to lock is calculated by applying the `ltvBoostLockRate` rate to the difference between the new and the old credit limits.
    /// See {applyTraitBoost} for details on the locking and unlocking mechanism.
    /// @dev emits multiple {LTVBoostLock} events
    /// @param _nftIndexes The indexes of the NFTs to boost
    /// @param _rateIncreasesBps The rate increase amounts, in basis points.
    function applyLTVBoost(
        uint256[] calldata _nftIndexes,
        uint128[] memory _rateIncreasesBps
    ) external nonReentrant {
        _applyLTVBoost(_nftIndexes, _rateIncreasesBps);
    }

    /// @notice Allows users to queue trait boost locks for release. The boost is disabled when the locked JPEG becomes available to be claimed,
    /// `lockReleaseDelay` seconds after calling this function. The JPEG can then be claimed by calling {withdrawTraitBoost}.
    /// @dev emits multiple {TraitBoostLockReleaseQueued} events
    /// @param _nftIndexes The indexes of the locks to queue for release
    function queueTraitBoostRelease(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _queueLockRelease(_nftIndexes, true);
    }

    /// @notice Allows users to queue LTV boost locks for release. The boost is disabled when the locked JPEG becomes available to be claimed,
    /// `lockReleaseDelay` seconds after calling this function. The JPEG can then be claimed by calling {withdrawLTVBoost}.
    /// @dev emits multiple {LTVBoostLockReleaseQueued} events
    /// @param _nftIndexes The indexes of the locks to queue for release
    function queueLTVBoostRelease(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _queueLockRelease(_nftIndexes, false);
    }

    /// @notice Allows users to cancel scheduled trait boost lock releases. The boost is maintained. It can only be called before `lockReleaseDelay` elapses.
    /// @param _nftIndexes The indexes of the locks to cancel release for
    /// @dev emits multiple {TraitBoostLockReleaseCancelled} events
    function cancelTraitBoostRelease(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _cancelLockRelease(_nftIndexes, true);
    }

    /// @notice Allows users to cancel scheduled ltv boost lock releases. The boost is maintained. It can only be called before `lockReleaseDelay` elapses.
    /// @param _nftIndexes The indexes of the locks to cancel release for
    /// @dev emits multiple {LTVBoostLockReleaseCancelled} events
    function cancelLTVBoostRelease(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _cancelLockRelease(_nftIndexes, false);
    }

    /// @notice Allows trait boost lock creators to unlock the JPEG associated to the NFT at index `_nftIndex`, provided the lock has been released.
    /// @dev emits multiple {TraitBoostUnlock} events
    /// @param _nftIndexes The indexes of the NFTs holding the locks.
    function withdrawTraitBoost(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _unlockJPEG(_nftIndexes, true);
    }

    /// @notice Allows ltv boost lock creators to unlock the JPEG associated to the NFT at index `_nftIndex`, provided the lock has been released.
    /// @dev emits multiple {LTVBoostUnlock} events
    /// @param _nftIndexes The indexes of the NFTs holding the locks.
    function withdrawLTVBoost(
        uint256[] calldata _nftIndexes
    ) external nonReentrant {
        _unlockJPEG(_nftIndexes, false);
    }

    /// @notice Allows the DAO to bypass the floor oracle and override the NFT floor value
    /// @param _newFloor The new floor
    function overrideFloor(uint256 _newFloor) external onlyOwner {
        if (_newFloor == 0) revert InvalidAmount(_newFloor);
        overriddenFloorValueETH = _newFloor;
        daoFloorOverride = true;

        emit DaoFloorChanged(_newFloor);
    }

    /// @notice Allows the DAO to stop overriding floor
    function disableFloorOverride() external onlyOwner {
        daoFloorOverride = false;
    }

    /// @notice Allows the DAO to change the multiplier of an NFT category
    /// @param _type The category hash
    /// @param _multiplier The new multiplier
    function setNFTTypeMultiplier(
        bytes32 _type,
        RateLib.Rate calldata _multiplier
    ) external onlyOwner {
        if (_type == bytes32(0)) revert InvalidNFTType(_type);
        if (!_multiplier.isValid() || _multiplier.isBelowOne())
            revert RateLib.InvalidRate();
        nftTypeValueMultiplier[_type] = _multiplier;
    }

    /// @notice Allows the DAO to add an NFT to a specific price category
    /// @param _nftIndexes The indexes to add to the category
    /// @param _type The category hash
    function setNFTType(
        uint256[] calldata _nftIndexes,
        bytes32 _type
    ) external onlyOwner {
        if (_type != bytes32(0) && nftTypeValueMultiplier[_type].numerator == 0)
            revert InvalidNFTType(_type);

        for (uint256 i; i < _nftIndexes.length; ++i) {
            nftTypes[_nftIndexes[i]] = _type;
        }
    }

    function setBaseCreditLimitRate(
        RateLib.Rate memory _baseCreditLimitRate
    ) external onlyOwner {
        _validateRateBelowOne(_baseCreditLimitRate);
        if (_baseCreditLimitRate.greaterThan(creditLimitRateCap))
            revert RateLib.InvalidRate();
        if (!baseLiquidationLimitRate.greaterThan(_baseCreditLimitRate))
            revert RateLib.InvalidRate();

        baseCreditLimitRate = _baseCreditLimitRate;
    }

    function setBaseLiquidationLimitRate(
        RateLib.Rate memory _liquidationLimitRate
    ) external onlyOwner {
        _validateRateBelowOne(_liquidationLimitRate);
        if (_liquidationLimitRate.greaterThan(liquidationLimitRateCap))
            revert RateLib.InvalidRate();
        if (!_liquidationLimitRate.greaterThan(baseCreditLimitRate))
            revert RateLib.InvalidRate();

        baseLiquidationLimitRate = _liquidationLimitRate;
    }

    function setCreditLimitRateCap(
        RateLib.Rate memory _creditLimitRate
    ) external onlyOwner {
        _validateRateBelowOne(_creditLimitRate);
        if (baseCreditLimitRate.greaterThan(_creditLimitRate))
            revert RateLib.InvalidRate();
        if (!baseLiquidationLimitRate.greaterThan(_creditLimitRate))
            revert RateLib.InvalidRate();

        creditLimitRateCap = _creditLimitRate;
    }

    function setLiquidationLimitRateCap(
        RateLib.Rate memory _liquidationLimitRate
    ) external onlyOwner {
        _validateRateBelowOne(_liquidationLimitRate);
        if (baseLiquidationLimitRate.greaterThan(_liquidationLimitRate))
            revert RateLib.InvalidRate();
        if (!_liquidationLimitRate.greaterThan(creditLimitRateCap))
            revert RateLib.InvalidRate();

        liquidationLimitRateCap = _liquidationLimitRate;
    }

    function setCigStakedRateIncrease(
        RateLib.Rate memory _cigStakedRateIncrease
    ) external onlyOwner {
        _validateRateBelowOne(_cigStakedRateIncrease);
        cigStakedRateIncrease = _cigStakedRateIncrease;
    }

    function setJPEGLockedMaxRateIncrease(
        RateLib.Rate memory _jpegLockedRateIncrease
    ) external onlyOwner {
        _validateRateBelowOne(_jpegLockedRateIncrease);
        jpegLockedMaxRateIncrease = _jpegLockedRateIncrease;
    }

    function setTraitBoostLockRate(
        RateLib.Rate memory _traitBoostLockRate
    ) external onlyOwner {
        _validateRateBelowOne(_traitBoostLockRate);
        traitBoostLockRate = _traitBoostLockRate;
    }

    function setLTVBoostLockRate(
        RateLib.Rate memory _ltvBoostLockRate
    ) external onlyOwner {
        _validateRateBelowOne(_ltvBoostLockRate);
        ltvBoostLockRate = _ltvBoostLockRate;
    }

    ///@dev See {applyLTVBoost}
    function _applyLTVBoost(
        uint256[] memory _nftIndexes,
        uint128[] memory _rateIncreasesBps
    ) internal {
        if (
            _nftIndexes.length != _rateIncreasesBps.length ||
            _nftIndexes.length == 0
        ) revert InvalidLength();

        RateLib.Rate memory _baseCreditLimit = baseCreditLimitRate;
        RateLib.Rate memory _maxRateIncrease = jpegLockedMaxRateIncrease;
        RateLib.Rate memory _lockRate = ltvBoostLockRate;

        IERC20Upgradeable _jpeg = jpeg;
        uint256 _floor = getFloorETH();
        uint256 _jpegPrice = _jpegPriceETH();
        uint256 _minLock = minJPEGToLock;
        uint256 _requiredJPEG;
        uint256 _jpegToRefund;

        for (uint256 i; i < _nftIndexes.length; ++i) {
            if (_rateIncreasesBps[i] >= 10000 || _rateIncreasesBps[i] == 0)
                revert InvalidAmount(_rateIncreasesBps[i]);

            RateLib.Rate memory _rateIncrease = RateLib.Rate(
                _rateIncreasesBps[i],
                10000
            );

            if (_rateIncrease.greaterThan(_maxRateIncrease))
                revert RateLib.InvalidRate();

            uint256 _jpegToLock = _calculateLTVBoostLock(
                _baseCreditLimit,
                _baseCreditLimit.sum(_rateIncrease),
                _lockRate,
                _floor,
                _jpegPrice
            );

            uint256 _index = _nftIndexes[i];
            JPEGLock memory _lock = ltvBoostPositions[_index];

            //prevent increasing ltv boost rate if lock is queued for withdrawal
            if (_lock.unlockAt > block.timestamp) revert LockExists(_index);

            if (_lock.owner != address(0) && _lock.unlockAt == 0) {
                if (
                    _lock.owner != msg.sender ||
                    !_rateIncrease.greaterThan(ltvBoostRateIncreases[_index])
                ) revert LockExists(_index);
                else if (_lock.lockedValue > _jpegToLock)
                    _jpegToLock = _lock.lockedValue;
            }

            if (_minLock > _jpegToLock) _jpegToLock = _minLock;

            _requiredJPEG += _jpegToLock;

            if (_lock.owner == msg.sender) _jpegToRefund += _lock.lockedValue;
            else if (_lock.lockedValue > 0)
                _jpeg.safeTransfer(_lock.owner, _lock.lockedValue);

            ltvBoostPositions[_index] = JPEGLock(msg.sender, 0, _jpegToLock);
            ltvBoostRateIncreases[_index] = _rateIncrease;

            emit LTVBoost(
                msg.sender,
                _index,
                _jpegToLock,
                _rateIncrease.numerator
            );
        }

        if (_requiredJPEG > _jpegToRefund)
            _jpeg.safeTransferFrom(
                msg.sender,
                address(this),
                _requiredJPEG - _jpegToRefund
            );
        else if (_requiredJPEG < _jpegToRefund)
            _jpeg.safeTransfer(msg.sender, _jpegToRefund - _requiredJPEG);
    }

    /// @dev see {applyTraitBoost}
    function _applyTraitBoost(uint256[] memory _nftIndexes) internal {
        if (_nftIndexes.length == 0) revert InvalidLength();

        RateLib.Rate memory _lockRate = traitBoostLockRate;

        IERC20Upgradeable _jpeg = jpeg;
        uint256 _floor = getFloorETH();
        uint256 _jpegPrice = _jpegPriceETH();
        uint256 _minLock = minJPEGToLock;
        uint256 _requiredJPEG;
        uint256 _jpegToRefund;

        for (uint256 i; i < _nftIndexes.length; ++i) {
            uint256 _index = _nftIndexes[i];

            bytes32 _nftType = nftTypes[_index];
            if (_nftType == bytes32(0)) revert InvalidNFTType(_nftType);

            JPEGLock memory _lock = traitBoostPositions[_index];
            if (
                _lock.owner != address(0) &&
                (_lock.unlockAt == 0 || _lock.unlockAt > block.timestamp)
            ) revert LockExists(_index);

            uint256 _jpegToLock = _calculateTraitBoostLock(
                _lockRate,
                _nftType,
                _floor,
                _jpegPrice
            );

            if (_minLock > _jpegToLock) revert InvalidNFTType(_nftType);

            _requiredJPEG += _jpegToLock;

            if (_lock.owner == msg.sender) _jpegToRefund += _lock.lockedValue;
            else if (_lock.lockedValue > 0)
                _jpeg.safeTransfer(_lock.owner, _lock.lockedValue);

            traitBoostPositions[_index] = JPEGLock(msg.sender, 0, _jpegToLock);

            emit TraitBoost(msg.sender, _index, _jpegToLock);
        }

        if (_requiredJPEG > _jpegToRefund)
            _jpeg.safeTransferFrom(
                msg.sender,
                address(this),
                _requiredJPEG - _jpegToRefund
            );
        else if (_requiredJPEG < _jpegToRefund)
            _jpeg.safeTransfer(msg.sender, _jpegToRefund - _requiredJPEG);
    }

    function _queueLockRelease(
        uint256[] calldata _nftIndexes,
        bool _isTraitBoost
    ) internal {
        uint256 _length = _nftIndexes.length;
        if (_length == 0) revert InvalidLength();

        uint256 _unlockTime = block.timestamp + lockReleaseDelay;
        for (uint256 i; i < _length; ++i) {
            uint256 _index = _nftIndexes[i];
            JPEGLock memory _lock;

            if (_isTraitBoost) {
                _lock = traitBoostPositions[_index];
                traitBoostPositions[_index].unlockAt = _unlockTime;

                emit TraitBoostReleaseQueued(_lock.owner, _index, _unlockTime);
            } else {
                _lock = ltvBoostPositions[_index];
                ltvBoostPositions[_index].unlockAt = _unlockTime;

                emit LTVBoostReleaseQueued(_lock.owner, _index, _unlockTime);
            }

            if (_lock.owner != msg.sender || _lock.unlockAt != 0)
                revert Unauthorized();
        }
    }

    function _cancelLockRelease(
        uint256[] calldata _nftIndexes,
        bool _isTraitBoost
    ) internal {
        uint256 _length = _nftIndexes.length;
        if (_length == 0) revert InvalidLength();

        for (uint256 i; i < _length; ++i) {
            uint256 _index = _nftIndexes[i];
            JPEGLock memory _lock;

            if (_isTraitBoost) {
                _lock = traitBoostPositions[_index];
                traitBoostPositions[_index].unlockAt = 0;

                emit TraitBoostReleaseCancelled(_lock.owner, _index);
            } else {
                _lock = ltvBoostPositions[_index];
                ltvBoostPositions[_index].unlockAt = 0;

                emit LTVBoostReleaseCancelled(_lock.owner, _index);
            }

            if (_lock.owner != msg.sender || block.timestamp >= _lock.unlockAt)
                revert Unauthorized();
        }
    }

    /// @dev See {withdrawTraitBoost} and {withdrawLTVBoost}
    function _unlockJPEG(
        uint256[] calldata _nftIndexes,
        bool _isTraitBoost
    ) internal {
        uint256 _length = _nftIndexes.length;
        if (_length == 0) revert InvalidLength();

        uint256 _jpegToSend;
        for (uint256 i; i < _length; ++i) {
            uint256 _index = _nftIndexes[i];
            JPEGLock memory _lock;

            if (_isTraitBoost) {
                _lock = traitBoostPositions[_index];
                delete traitBoostPositions[_index];
                emit TraitBoostUnlock(msg.sender, _index, _lock.lockedValue);
            } else {
                _lock = ltvBoostPositions[_index];
                delete ltvBoostPositions[_index];
                delete ltvBoostRateIncreases[_index];

                emit LTVBoostUnlock(msg.sender, _index, _lock.lockedValue);
            }

            if (
                _lock.owner != msg.sender ||
                _lock.unlockAt == 0 ||
                _lock.unlockAt > block.timestamp
            ) revert Unauthorized();

            _jpegToSend += _lock.lockedValue;
        }

        jpeg.safeTransfer(msg.sender, _jpegToSend);
    }

    function _calculateTraitBoostLock(
        RateLib.Rate memory _lockRate,
        bytes32 _nftType,
        uint256 _floor,
        uint256 _jpegPrice
    ) internal view returns (uint256) {
        RateLib.Rate memory multiplier = nftTypeValueMultiplier[_nftType];

        if (multiplier.numerator == 0 || multiplier.denominator == 0) return 0;

        return
            (((_floor * multiplier.numerator) /
                multiplier.denominator -
                _floor) *
                1 ether *
                _lockRate.numerator) /
            _lockRate.denominator /
            _jpegPrice;
    }

    function _calculateLTVBoostLock(
        RateLib.Rate memory _creditLimitRate,
        RateLib.Rate memory _boostedCreditLimitRate,
        RateLib.Rate memory _lockRate,
        uint256 _floor,
        uint256 _jpegPrice
    ) internal pure returns (uint256) {
        uint256 baseCreditLimit = (_floor * _creditLimitRate.numerator) /
            _creditLimitRate.denominator;
        uint256 boostedCreditLimit = (_floor *
            _boostedCreditLimitRate.numerator) /
            _boostedCreditLimitRate.denominator;

        return
            ((((boostedCreditLimit - baseCreditLimit) * _lockRate.numerator) /
                _lockRate.denominator) * 1 ether) / _jpegPrice;
    }

    function _rateAfterBoosts(
        RateLib.Rate memory _baseRate,
        RateLib.Rate memory _cap,
        address _owner,
        uint256 _nftIndex
    ) internal view returns (RateLib.Rate memory) {
        if (cigStaking.isUserStaking(_owner))
            _baseRate = _baseRate.sum(cigStakedRateIncrease);

        if (ltvBoostPositions[_nftIndex].owner != address(0)) {
            uint256 _unlockAt = ltvBoostPositions[_nftIndex].unlockAt;
            if (_unlockAt == 0 || _unlockAt > block.timestamp)
                _baseRate = _baseRate.sum(ltvBoostRateIncreases[_nftIndex]);
        }

        if (_baseRate.greaterThan(_cap)) return _cap;

        return _baseRate;
    }

    /// @dev Returns the current JPEG price in ETH
    /// @return result The current JPEG price, 18 decimals
    function _jpegPriceETH() internal returns (uint256) {
        return aggregator.consultJPEGPriceETH(address(jpeg));
    }

    /// @dev Validates a rate. The denominator must be greater than zero and greater than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateBelowOne(RateLib.Rate memory _rate) internal pure {
        if (!_rate.isValid() || _rate.isAboveOne())
            revert RateLib.InvalidRate();
    }
}