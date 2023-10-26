// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ITimeAllianceGuildNft} from "../TimeAllianceGuildNft/ITimeAllianceGuildNft.sol";

contract TimeAllianceGuildSale is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    /// @notice $TIME Token
    IERC20 public timeToken;

    /// @notice NFT Token Issued
    ITimeAllianceGuildNft public nftToken;

    /// @notice Treasury wallet
    address public treasury;

    /// @notice Mapping package ID to its price
    mapping(uint256 => uint256) public packagePrices;

    /// @notice Price of $TIME per 1 ETH
    uint256 public timePrice;

    /// @dev Referral data
    struct ReferrerData {
        uint128 kickbackRate;
        uint128 bonusRate;
    }

    /// @notice Mapping every address to ReferrerData
    mapping(address => ReferrerData) _referrerData;

    /// @notice Percentage rebate in tokens
    uint256 public timeTokenPercent;

    /// @notice Global bonus rate
    uint256 public globalBonusRate;

    /// @notice Global kickback rate
    uint256 public globalKickbackRate;

    /// @notice Sale event
    event Sale(
        address indexed buyer,
        address indexed referrer,
        uint256 timeBonus,
        uint256 kickbackRate,
        uint256 packageId,
        uint256 timePrice,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address timeToken_,
        address nftToken_,
        address treasury_
    ) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();
        timeToken = IERC20(timeToken_);
        nftToken = ITimeAllianceGuildNft(nftToken_);
        setPackagePrice(0, 0.31 ether);
        setPackagePrice(1, 0.94 ether);
        setPackagePrice(2, 1.57 ether);
        setPackagePrice(3, 3.15 ether);
        setTimeTokenRate(1000);
        setGlobalRates(1500, 0);
        setTreasury(treasury_);
        _pause();
    }

    function buy(
        uint256 packageId,
        address referrer
    ) public payable whenNotPaused {
        require(packagePrices[packageId] != 0, "Invalid Package");
        require(msg.value >= packagePrices[packageId], "Not Enough ETH");

        // Amount to distribute to treasury
        uint256 treasuryAmount = msg.value;

        // Percentage of the sale gets $TIME distributed
        uint256 timeTokens = timePrice > 0
            ? (((msg.value * timePrice) / 1 ether) * timeTokenPercent) / 10000
            : 0;

        // Mint NFT
        nftToken.mint(msg.sender, packageId, 1);

        // Calculate referral and treasury amounts
        if (_validReferrer(referrer)) {
            uint256 kickbackRate = _kickbackRate(referrer);
            uint256 referralAmount = (msg.value * kickbackRate) / 10000;
            treasuryAmount = msg.value - referralAmount;

            // Mint $TIME bonus to the referrer
            uint256 timeBonus = getBonusTokens(packageId, referrer);
            timeTokens += timeBonus;

            // Send referral fee
            payable(referrer).transfer(referralAmount);

            // Emit sale event
            emit Sale(
                msg.sender,
                referrer,
                timeBonus,
                kickbackRate,
                packageId,
                timePrice,
                msg.value
            );
        } else {
            emit Sale(
                msg.sender,
                address(0),
                0,
                0,
                packageId,
                timePrice,
                msg.value
            );
        }

        // transfer TIME token
        if (timeTokens > 0) {
            timeToken.transfer(msg.sender, timeTokens);
        }

        payable(treasury).transfer(treasuryAmount);
    }

    function getBonusTokens(
        uint256 packageId,
        address referrer
    ) public view returns (uint256) {
        return
            timePrice == 0 || !_validReferrer(referrer)
                ? 0
                : (((packagePrices[packageId] * timePrice) / 1 ether) *
                    _bonusRate(referrer)) / 10000;
    }

    function _validReferrer(address address_) private view returns (bool) {
        return
            address_ != address(0) &&
            address_ != msg.sender &&
            !_isContract(address_);
    }

    function _bonusRate(address address_) private view returns (uint256) {
        uint256 bonusRate = _referrerData[address_].bonusRate;
        return uint256(bonusRate > 0 ? bonusRate : globalBonusRate);
    }

    function _kickbackRate(address address_) private view returns (uint256) {
        uint256 kickbackRate = _referrerData[address_].kickbackRate;
        return uint256(kickbackRate > 0 ? kickbackRate : globalKickbackRate);
    }

    function setTreasury(address address_) public onlyOwner {
        treasury = address_;
    }

    function setTimePrice(uint256 _timePrice) public onlyOwner {
        timePrice = _timePrice;
    }

    function setGlobalRates(
        uint256 globalKickbackRate_,
        uint256 globalBonusRate_
    ) public onlyOwner {
        globalBonusRate = globalBonusRate_;
        globalKickbackRate = globalKickbackRate_;
    }

    function setPackagePrice(uint256 package, uint256 price) public onlyOwner {
        packagePrices[package] = price;
    }

    function setReferrerInfo(
        address address_,
        uint128 kickbackRate,
        uint128 bonusRate
    ) public onlyOwner {
        _referrerData[address_].kickbackRate = kickbackRate;
        _referrerData[address_].bonusRate = bonusRate;
    }

    function setTimeTokenRate(uint256 percent) public onlyOwner {
        require(percent <= 10000, "Invalid");
        timeTokenPercent = percent;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed");
    }

    function withdrawERC20() public onlyOwner {
        timeToken.transfer(owner(), timeToken.balanceOf(address(this)));
    }

    function toggle() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}