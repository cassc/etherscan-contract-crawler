// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IUniswapV2Oracle.sol";
import "../interfaces/IJPEGOraclesAggregator.sol";

contract NFTValueProvider is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidNFTType(bytes32 nftType);
    error InvalidRate(Rate rate);
    error InvalidUnlockTime(uint256 unlockTime);
    error ExistingLock(uint256 index);
    error InvalidAmount(uint256 amount);
    error InvalidOracleResults();
    error Unauthorized();
    error ZeroAddress();
    error InvalidLength();

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

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

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
    Rate public valueIncreaseLockRate;
    /// @notice Minimum amount of JPEG to lock for trait boost
    uint256 public minJPEGToLock;

    mapping(uint256 => bytes32) public nftTypes;
    mapping(bytes32 => Rate) public nftTypeValueMultiplier;
    mapping(uint256 => JPEGLock) public lockPositions;

    /// @notice This function is only called once during deployment of the proxy contract. It's not called after upgrades.
    /// @param _jpeg The JPEG token
    /// @param _aggregator The JPEG floor oracles aggregator
    /// @param _valueIncreaseLockRate The rate used to calculate the amount of JPEG to lock based on the NFT's value increase
    /// @param _minJPEGToLock Minimum amount of JPEG to lock to apply the trait boost
    function initialize(
        IERC20Upgradeable _jpeg,
        IJPEGOraclesAggregator _aggregator,
        Rate calldata _valueIncreaseLockRate,
        uint256 _minJPEGToLock
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        if (address(_jpeg) == address(0)) revert ZeroAddress();
        if (address(_aggregator) == address(0)) revert ZeroAddress();

        _validateRateBelowOne(_valueIncreaseLockRate);

        jpeg = _jpeg;
        aggregator = _aggregator;
        valueIncreaseLockRate = _valueIncreaseLockRate;
        minJPEGToLock = _minJPEGToLock;
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
                valueIncreaseLockRate.numerator) /
            valueIncreaseLockRate.denominator /
            _jpegPrice;
    }

    /// @return The floor value for the collection, in ETH.
    function getFloorETH() public view returns (uint256) {
        if (daoFloorOverride) return overriddenFloorValueETH;
        else return aggregator.getFloorETH();
    }

    /// @param _nftIndex The NFT to return the value of
    /// @return The value in ETH of the NFT at index `_nftIndex`, with 18 decimals.
    function getNFTValueETH(uint256 _nftIndex) external view returns (uint256) {
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
    /// @dev emits multiple {JPEGLocked} events
    /// @param _nftIndexes The indexes of the non floor NFTs to boost
    /// @param _unlocks The locks expiration times
    function applyTraitBoost(
        uint256[] calldata _nftIndexes,
        uint256[] calldata _unlocks
    ) external nonReentrant {
        if (_nftIndexes.length != _unlocks.length) revert InvalidLength();

        uint256 requiredJpeg;
        uint256 jpegToRefund;
        for (uint256 i; i < _nftIndexes.length; ++i) {
            uint256 index = _nftIndexes[i];

            bytes32 nftType = nftTypes[index];
            if (nftType == bytes32(0)) revert InvalidNFTType(nftType);

            uint256 unlockAt = _unlocks[i];

            JPEGLock storage jpegLock = lockPositions[index];
            if (block.timestamp >= unlockAt || jpegLock.unlockAt >= unlockAt)
                revert InvalidUnlockTime(unlockAt);

            uint256 jpegToLock = calculateJPEGToLock(nftType, _jpegPriceETH());

            if (minJPEGToLock >= jpegToLock) revert InvalidNFTType(nftType);

            uint256 previousLockValue = jpegLock.lockedValue;
            address previousOwner = jpegLock.owner;

            jpegLock.lockedValue = jpegToLock;
            jpegLock.unlockAt = unlockAt;
            jpegLock.owner = msg.sender;

            requiredJpeg += jpegToLock;

            if (previousOwner == msg.sender) jpegToRefund += previousLockValue;
            else if (previousLockValue > 0)
                jpeg.safeTransfer(previousOwner, previousLockValue);

            emit JPEGLocked(msg.sender, index, jpegToLock, unlockAt);
        }

        if (requiredJpeg > jpegToRefund)
            jpeg.safeTransferFrom(
                msg.sender,
                address(this),
                requiredJpeg - jpegToRefund
            );
        else if (requiredJpeg < jpegToRefund)
            jpeg.safeTransfer(msg.sender, jpegToRefund - requiredJpeg);
    }

    /// @notice Allows lock creators to unlock the JPEG associated to the NFT at index `_nftIndex`, provided the lock expired.
    /// @dev emits a {JPEGUnlocked} event
    /// @param _nftIndexes The indexes of the NFTs holding the locks.
    function unlockJPEG(uint256[] calldata _nftIndexes) external nonReentrant {
        uint256 length = _nftIndexes.length;
        if (length == 0)
            revert InvalidLength();

        uint256 jpegToSend;
        for (uint256 i; i < length; ++i) {
            uint256 index = _nftIndexes[i];
            JPEGLock memory jpegLock = lockPositions[index];
            if (jpegLock.owner != msg.sender) revert Unauthorized();

            if (block.timestamp < jpegLock.unlockAt) revert Unauthorized();

            jpegToSend += jpegLock.lockedValue;

            delete lockPositions[index];

            emit JPEGUnlocked(msg.sender, index, jpegLock.lockedValue);
        }

        jpeg.safeTransfer(msg.sender, jpegToSend);
    }

    function addLocks(
        uint256[] calldata _nftIndexes,
        JPEGLock[] calldata _locks
    ) external onlyOwner {
        if (_nftIndexes.length != _locks.length || _nftIndexes.length == 0)
            revert InvalidLength();

        for (uint256 i; i < _nftIndexes.length; ++i) {
            if (lockPositions[_nftIndexes[i]].owner != address(0))
                revert ExistingLock(_nftIndexes[i]);
            lockPositions[_nftIndexes[i]] = _locks[i];
        }
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
    function setNFTTypeMultiplier(bytes32 _type, Rate calldata _multiplier)
        external
        onlyOwner
    {
        if (_type == bytes32(0)) revert InvalidNFTType(_type);
        _validateRateAboveOne(_multiplier);
        nftTypeValueMultiplier[_type] = _multiplier;
    }

    /// @notice Allows the DAO to add an NFT to a specific price category
    /// @param _nftIndexes The indexes to add to the category
    /// @param _type The category hash
    function setNFTType(uint256[] calldata _nftIndexes, bytes32 _type)
        external
        onlyOwner
    {
        if (_type != bytes32(0) && nftTypeValueMultiplier[_type].numerator == 0)
            revert InvalidNFTType(_type);

        for (uint256 i; i < _nftIndexes.length; ++i) {
            nftTypes[_nftIndexes[i]] = _type;
        }
    }

    /// @dev Returns the current JPEG price in ETH
    /// @return result The current JPEG price, 18 decimals
    function _jpegPriceETH() internal returns (uint256) {
        return aggregator.consultJPEGPriceETH(address(jpeg));
    }

    /// @dev Validates a rate. The denominator must be greater than zero and less than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateAboveOne(Rate memory _rate) internal pure {
        if (_rate.denominator == 0 || _rate.numerator < _rate.denominator)
            revert InvalidRate(_rate);
    }

    /// @dev Validates a rate. The denominator must be greater than zero and greater than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateBelowOne(Rate memory _rate) internal pure {
        if (_rate.denominator == 0 || _rate.denominator < _rate.numerator)
            revert InvalidRate(_rate);
    }
}