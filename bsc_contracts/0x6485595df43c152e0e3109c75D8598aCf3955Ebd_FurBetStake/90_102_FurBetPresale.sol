// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
// Interfaces.
import "./interfaces/IFurBetToken.sol";
import "./interfaces/IFurBetStake.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurbetPresale
 * @notice This is the presale contract for Furbet
 */

/// @custom:security-contact [email protected]
contract FurBetPresale is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _start = 1659463200; // Tue Aug 02 2022 18:00:00 GMT+0000
        _presaleOneTime = 10 minutes;
        _presaleTwoTime = 25 minutes;
        _presaleThreeTime = 2 days;
        _presaleFourTime = _presaleThreeTime + 15 minutes;
        _presaleFiveTime = _presaleThreeTime + 4 days;
        _presaleOnePrice = 50e16;
        _presaleTwoPrice = 50e16;
        _presaleThreePrice = 50e16;
        _presaleFourPrice = 75e16;
        _presaleFivePrice = 75e16;
        _presaleOneMaxForSale = 750000e18;
        _presaleTwoMaxForSale = 750000e18;
        _presaleThreeMaxForSale = 750000e18;
        _presaleFourMaxForSale = 1500000e18;
        _presaleFiveMaxForSale = 1500000e18;
        _presaleOneMinVaultBalance = 25e18;
        _presaleTwoMinVaultBalance = 25e18;
        _presaleThreeMinVaultBalance = 25e18;
        _presaleFourMinVaultBalance = 0;
        _presaleFiveMinVaultBalance = 0;
        _presaleOneMinRewardRate = 250;
        _presaleTwoMinRewardRate = 200;
        _presaleThreeMinRewardRate = 200;
        _presaleFourMinRewardRate = 0;
        _presaleFiveMinRewardRate = 0;
        _presaleOneMaxPerAddress = 500e18;
        _presaleTwoMaxPerAddress = 500e18;
        _presaleThreeMaxPerAddress = 0;
        _presaleFourMaxPerAddress = 2000e18;
        _presaleFiveMaxPerAddress = 0;
    }

    /**
     * Properties.
     */
    uint256 private _start; // Presale start time.
    uint256 private _sold; // Amount of tokens sold.
    uint256 private _presaleOneTime;
    uint256 private _presaleTwoTime;
    uint256 private _presaleThreeTime;
    uint256 private _presaleFourTime;
    uint256 private _presaleFiveTime;
    uint256 private _presaleOnePrice;
    uint256 private _presaleTwoPrice;
    uint256 private _presaleThreePrice;
    uint256 private _presaleFourPrice;
    uint256 private _presaleFivePrice;
    uint256 private _presaleOneMaxForSale;
    uint256 private _presaleTwoMaxForSale;
    uint256 private _presaleThreeMaxForSale;
    uint256 private _presaleFourMaxForSale;
    uint256 private _presaleFiveMaxForSale;
    uint256 private _presaleOneMinVaultBalance;
    uint256 private _presaleTwoMinVaultBalance;
    uint256 private _presaleThreeMinVaultBalance;
    uint256 private _presaleFourMinVaultBalance;
    uint256 private _presaleFiveMinVaultBalance;
    uint256 private _presaleOneMinRewardRate;
    uint256 private _presaleTwoMinRewardRate;
    uint256 private _presaleThreeMinRewardRate;
    uint256 private _presaleFourMinRewardRate;
    uint256 private _presaleFiveMinRewardRate;
    uint256 private _presaleOneMaxPerAddress;
    uint256 private _presaleTwoMaxPerAddress;
    uint256 private _presaleThreeMaxPerAddress;
    uint256 private _presaleFourMaxPerAddress;
    uint256 private _presaleFiveMaxPerAddress;

    /**
     * Mappings.
     */
    mapping(address => uint256) private _purchased; // Maps address to amount of tokens purchased.

    /**
     * Get start.
     * @return uint256 Start time.
     */
    function getStart() external view returns (uint256)
    {
        return _start;
    }

    /**
     * Get sold.
     * @return uint256 Total sold.
     */
    function getSold() external view returns (uint256)
    {
        return _sold;
    }

    /**
     * Get purchased.
     * @param participant_ Participant address.
     * @return uint256 Amount of tokens purchased.
     */
    function getPurchased(address participant_) external view returns (uint256)
    {
        return _purchased[participant_];
    }

    /**
     * Presale type.
     * @return uint256 - Type of presale (0 - 6).
     */
    function presaleType() public view returns (uint256)
    {
        if(block.timestamp < _start) return 0;
        if(block.timestamp < _start + _presaleOneTime) return 1;
        if(block.timestamp < _start + _presaleTwoTime) return 2;
        if(block.timestamp < _start + _presaleThreeTime) return 3;
        if(block.timestamp < _start + _presaleFourTime) return 4;
        if(block.timestamp < _start + _presaleFiveTime) return 5;
        return 6;
    }

    /**
     * Get price.
     * @param type_ Presale type.
     * @return uint256 Price per token.
     */
    function getPrice(uint256 type_) public view returns (uint256)
    {
        if(type_ == 1) return _presaleOnePrice;
        if(type_ == 2) return _presaleTwoPrice;
        if(type_ == 3) return _presaleThreePrice;
        if(type_ == 4) return _presaleFourPrice;
        if(type_ == 5) return _presaleFivePrice;
        return 0;
    }

    /**
     * Get max for sale.
     * @param type_ Presale type.
     * @return uint256 Max for sale.
     */
    function getMaxForSale(uint256 type_) public view returns (uint256)
    {
        if(type_ == 1) return _presaleOneMaxForSale;
        if(type_ == 2) return _presaleTwoMaxForSale;
        if(type_ == 3) return _presaleThreeMaxForSale;
        if(type_ == 4) return _presaleFourMaxForSale;
        if(type_ == 5) return _presaleFiveMaxForSale;
        return 0;
    }

    /**
     * Get min vault balance.
     * @param type_ Presale type.
     * @return uint256 Minimum vault balance.
     */
    function getMinVaultBalance(uint256 type_) public view returns (uint256)
    {
        if(type_ == 1) return _presaleOneMinVaultBalance;
        if(type_ == 2) return _presaleTwoMinVaultBalance;
        if(type_ == 3) return _presaleThreeMinVaultBalance;
        if(type_ == 4) return _presaleFourMinVaultBalance;
        if(type_ == 5) return _presaleFiveMinVaultBalance;
        return 0;
    }

    /**
     * Get min reward rate.
     * @param type_ Presale type.
     * @return uint256 Minimum reward rate.
     */
    function getMinRewardRate(uint256 type_) public view returns (uint256)
    {
        if(type_ == 1) return _presaleOneMinRewardRate;
        if(type_ == 2) return _presaleTwoMinRewardRate;
        if(type_ == 3) return _presaleThreeMinRewardRate;
        if(type_ == 4) return _presaleFourMinRewardRate;
        if(type_ == 5) return _presaleFiveMinRewardRate;
        return 0;
    }

    /**
     * Get max per address.
     * @param type_ Presale type.
     * @return uint256 Max per address.
     */
    function getMaxPerAddress(uint256 type_) public view returns (uint256)
    {
        if(type_ == 1) return _presaleOneMaxPerAddress;
        if(type_ == 2) return _presaleTwoMaxPerAddress;
        if(type_ == 3) return _presaleThreeMaxPerAddress;
        if(type_ == 4) return _presaleFourMaxPerAddress;
        if(type_ == 5) return _presaleFiveMaxPerAddress;
        return 0;
    }

    /**
     * Presale.
     * @param amount_ Amount of tokens to buy.
     */
    function presale(uint256 amount_) public whenNotPaused
    {
        uint256 _type_ = presaleType();
        require(_type_ > 0, "Presale has not started yet.");
        require(_type_ < 6, "Presale has ended.");
        uint256 _price_ = getPrice(_type_);
        uint256 _maxForSale_ = getMaxForSale(_type_);
        uint256 _minVaultBalance_ = getMinVaultBalance(_type_);
        uint256 _minRewardRate_ = getMinRewardRate(_type_);
        uint256 _maxPerAddress_ = getMaxPerAddress(_type_);
        require(_sold + amount_ <= _maxForSale_, "Presale is full.");
        if(_maxPerAddress_ > 0) {
            require(_purchased[msg.sender] + amount_ <= _maxPerAddress_, "You have reached the maximum amount of tokens you can purchase.");
        }
        if(_minVaultBalance_ > 0 || _minRewardRate_ > 0) {
            IVault _vault_ = IVault(addressBook.get("vault"));
            if(_minVaultBalance_ > 0) {
                require(_vault_.participantBalance(msg.sender) >= _minVaultBalance_, "You do not have enough tokens in the vault.");
            }
            if(_minRewardRate_ > 0) {
                require(_vault_.rewardRate(msg.sender) >= _minRewardRate_, "You do not have the correct reward rate.");
            }
        }
        IERC20 _payment_ = IERC20(addressBook.get("payment"));
        require(_payment_.transferFrom(msg.sender, addressBook.get("safe"), _price_ * (amount_ / (10 ** 18))), "Unable to transfer tokens.");
        _sold += amount_;
        _purchased[msg.sender] += amount_;
        IFurBetToken _token_ = IFurBetToken(addressBook.get("furbettoken"));
        IFurBetStake _stake_ = IFurBetStake(addressBook.get("furbetstake"));
        _token_.mint(address(this), amount_);
        _token_.approve(address(_stake_), amount_ / 4);
        _stake_.stakeFor(msg.sender, 1, amount_ / 4);
        _token_.approve(address(_stake_), amount_ / 4);
        _stake_.stakeFor(msg.sender, 2, amount_ / 4);
        _token_.approve(address(_stake_), amount_ / 4);
        _stake_.stakeFor(msg.sender, 3, amount_ / 4);
        _token_.approve(address(_stake_), amount_ / 4);
        _stake_.stakeFor(msg.sender, 4, amount_ / 4);
    }

    /**
     * Set start.
     * @param start_ New start time.
     */
    function setStart(uint256 start_) external onlyOwner
    {
        _start = start_;
    }
}