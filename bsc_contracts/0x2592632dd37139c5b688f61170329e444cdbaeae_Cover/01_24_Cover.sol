/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./02_24_SafeERC20Upgradeable.sol";
import "./03_24_IERC20Upgradeable.sol";
import "./04_24_SafeMathUpgradeable.sol";
import "./05_24_OwnableUpgradeable.sol";
import "./06_24_PausableUpgradeable.sol";
import "./07_24_ReentrancyGuardUpgradeable.sol";
import "./08_24_AddressUpgradeable.sol";

import {ISecurityMatrix} from "./09_24_ISecurityMatrix.sol";
import {Math} from "./10_24_Math.sol";
import {Constant} from "./11_24_Constant.sol";
import {ICoverConfig} from "./12_24_ICoverConfig.sol";
import {ICoverData} from "./13_24_ICoverData.sol";
import {ICoverQuotation} from "./14_24_ICoverQuotation.sol";
import {ICapitalPool} from "./15_24_ICapitalPool.sol";
import {IPremiumPool} from "./16_24_IPremiumPool.sol";
import {IExchangeRate} from "./17_24_IExchangeRate.sol";
import {IReferralProgram} from "./18_24_IReferralProgram.sol";
import {IProduct} from "./19_24_IProduct.sol";
import {ICover} from "./20_24_ICover.sol";
import {ICoverPurchase} from "./21_24_ICoverPurchase.sol";
import {ICoverCancellation} from "./22_24_ICoverCancellation.sol";

contract Cover is ICover, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // the security matrix address
    address public smx;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the cover quotation address
    address public quotation;
    // the capital pool address
    address public capitalPool;
    // the premium pool address
    address public premiumPool;
    // the insur token address
    address public insur;

    // buy cover maxmimum block number latency
    uint256 public buyCoverMaxBlkNumLatency;
    // buy cover signer flag map (signer -> true/false)
    mapping(address => bool) public buyCoverSignerFlagMap;
    // buy cover owner nonce flag map (owner -> nonce -> true/false)
    mapping(address => mapping(uint256 => bool)) public buyCoverNonceFlagMap;

    // the exchange rate address
    address public exchangeRate;

    // the referral program address
    address public referralProgram;

    // the product address
    address public product;

    // the cover purchase address
    address public coverPurchase;

    // the cover cancellation address
    address public coverCancellation;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setup(
        address securityMatrixAddress,
        address insurTokenAddress,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _coverQuotationAddress,
        address _capitalPool,
        address _premiumPool,
        address _exchangeRate,
        address _referralProgram,
        address _productAddress,
        address _coverPurchase,
        address _coverCancellation
    ) external onlyOwner {
        require(securityMatrixAddress != address(0), "S:1");
        require(insurTokenAddress != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_coverQuotationAddress != address(0), "S:5");
        require(_capitalPool != address(0), "S:6");
        require(_premiumPool != address(0), "S:7");
        require(_exchangeRate != address(0), "S:8");
        require(_referralProgram != address(0), "S:9");
        require(_productAddress != address(0), "S:10");
        require(_coverPurchase != address(0), "S:11");
        require(_coverCancellation != address(0), "S:12");
        smx = securityMatrixAddress;
        insur = insurTokenAddress;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        quotation = _coverQuotationAddress;
        capitalPool = _capitalPool;
        premiumPool = _premiumPool;
        exchangeRate = _exchangeRate;
        referralProgram = _referralProgram;
        product = _productAddress;
        coverPurchase = _coverPurchase;
        coverCancellation = _coverCancellation;
    }

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    event BuyCoverEvent(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, uint256 estimatedPremium, uint256 coverStatus);

    event BuyCoverEventV2(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, uint256 estimatedPremium, uint256 coverStatus, uint256 delayEffectiveDays);

    event BuyCoverOwnerRewardEvent(address indexed owner, uint256 rewardPctg, uint256 insurRewardAmt);

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable override whenNotPaused nonReentrant {
        {
            bytes memory msg1 = abi.encodePacked(address(this), products, durationInDays, amounts, currency);
            bytes memory msg2 = abi.encodePacked(owner, referralCode, currency, premiumAmount, helperParameters, securityParameters);
            bytes32 msgHash = keccak256(abi.encodePacked(msg1, msg2));
            require(_checkSignature(msgHash, v[0], r[0], s[0]), "BCV1: 1");
        }
        address[] memory addresses = new address[](3);
        addresses[0] = owner;
        addresses[1] = currency;
        addresses[2] = currency;
        _buyCover(products, durationInDays, amounts, addresses, premiumAmount, referralCode, helperParameters, securityParameters, "");
    }

    function buyCoverV2(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        address premiumCurrency,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable override whenNotPaused nonReentrant {
        {
            bytes memory msg1 = abi.encodePacked(address(this), products, durationInDays, amounts, currency);
            bytes memory msg2 = abi.encodePacked(owner, referralCode, premiumCurrency, premiumAmount, helperParameters, securityParameters);
            bytes32 msgHash = keccak256(abi.encodePacked(msg1, msg2));
            require(_checkSignature(msgHash, v[0], r[0], s[0]), "BCV2: 1");
        }
        address[] memory addresses = new address[](3);
        addresses[0] = owner;
        addresses[1] = currency;
        addresses[2] = premiumCurrency;
        _buyCover(products, durationInDays, amounts, addresses, premiumAmount, referralCode, helperParameters, securityParameters, "");
    }

    function buyCoverV3(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        string memory freeText,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable override whenNotPaused nonReentrant {
        {
            bytes memory msg1 = abi.encodePacked(address(this), products, durationInDays, amounts, addresses);
            bytes memory msg2 = abi.encodePacked(premiumAmount, referralCode, helperParameters, securityParameters, freeText);
            bytes32 msgHash = keccak256(abi.encodePacked(msg1, msg2));
            require(_checkSignature(msgHash, v[0], r[0], s[0]), "BCV3: 1");
        }
        _buyCover(products, durationInDays, amounts, addresses, premiumAmount, referralCode, helperParameters, securityParameters, freeText);
    }

    function _buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        string memory freeText
    ) internal {
        // check the number of cover details
        require(products.length == durationInDays.length, "BC: 1");
        require(products.length == amounts.length, "BC: 2");

        // check the address list
        // addresses[0] -> owner (the cover owner address)
        // addresses[1] -> currency (the cover amount currency)
        // addresses[2] -> premiumCurrency (the cover premium currency)
        require(ICoverConfig(cfg).isValidCurrency(addresses[1]) && ICoverConfig(cfg).isValidCurrency(addresses[2]), "BC: 3");

        // check the beneficiary address list (its length is 2)
        require(addresses[0] != address(0), "BC: 4");
        require(address(uint160(referralCode)) != address(0), "BC: 5");

        // check the helper parameters (its length is 4)
        // helperParameters[0] -> totalAmounts (the sum of cover amounts)
        // helperParameters[1] -> totalWeight (the sum of cover amount * cover duration * cover unit cost)
        // helperParameters[2] -> coverOwnerRewardPctg (the cover owner reward perentageX10000 of premium, 0 if not set)
        // helperParameters[3] -> referralRewardPctg (the referral reward perentageX10000 of premium, 0 if not set)
        require(helperParameters.length == 4, "BC: 6");

        // check the security parameters (its length is 2)
        // securityParameters[0] -> blockNumber (the block number when the signature is generated off-chain)
        // securityParameters[1] -> nonce (the nonce of the cover owner, can be timestamp in seconds)
        require(securityParameters.length == 2, "BC: 7");

        // check the block number latency
        require((block.number >= securityParameters[0]) && (block.number - securityParameters[0] <= buyCoverMaxBlkNumLatency), "BC: 8");

        // check the cover owner nonce flag
        require(!buyCoverNonceFlagMap[addresses[0]][securityParameters[1]], "BC: 9");
        buyCoverNonceFlagMap[addresses[0]][securityParameters[1]] = true;

        // check and receive the premium from this transaction
        _receivePremium(_msgSender(), addresses[2], premiumAmount);

        // process the cover creation and reward distribution
        ICoverPurchase(coverPurchase).buyCover(products, durationInDays, amounts, addresses, premiumAmount, referralCode, helperParameters, freeText);
    }

    event AddCoverFreeTextEvent(address indexed owner, uint256 coverId, string freeText);

    function addCoverFreeText(
        address owner,
        uint256 coverId,
        uint256[] memory securityParameters,
        string memory freeText,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external override whenNotPaused nonReentrant {
        // check msg sender
        require(_msgSender() == owner, "ACFT: 1");

        // check securityParameters (in the same format as buyCover())
        require(securityParameters.length == 2, "ACFT: 2");
        require((block.number >= securityParameters[0]) && (block.number - securityParameters[0] <= buyCoverMaxBlkNumLatency), "ACFT: 3");
        bytes32 msgHash = keccak256(abi.encodePacked(address(this), owner, coverId, securityParameters, freeText));
        require(_checkSignature(msgHash, v[0], r[0], s[0]), "ACFT: 4");
        require(!buyCoverNonceFlagMap[owner][securityParameters[1]], "ACFT: 5");
        buyCoverNonceFlagMap[owner][securityParameters[1]] = true;

        // check cover status and free text
        require(ICoverData(data).getAdjustedCoverStatus(owner, coverId) == Constant.COVERSTATUS_ACTIVE, "ACFT: 6");
        require(bytes(ICoverData(data).getCoverFreeText(owner, coverId)).length == 0, "ACFT: 7");
        require(bytes(freeText).length > 0, "ACFT: 8");

        ICoverData(data).setCoverFreeText(owner, coverId, freeText);
        emit AddCoverFreeTextEvent(owner, coverId, freeText);
    }

    function cancelCover(uint256 coverId) external override whenNotPaused nonReentrant {
        address owner = _msgSender();
        // process the request and refund unearned premium in INSUR token
        uint256 refundINSURAmount = ICoverCancellation(coverCancellation).cancelCover(owner, coverId);
        if (refundINSURAmount > 0) {
            IERC20Upgradeable(insur).safeTransfer(owner, refundINSURAmount);
        }
    }

    function _checkSignature(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        address signer = ecrecover(prefixedHash, v, r, s);
        return buyCoverSignerFlagMap[signer];
    }

    function _receivePremium(
        address msgSender,
        address premiumCurrency,
        uint256 premiumAmount
    ) internal {
        if (premiumCurrency == Constant.BCNATIVETOKENADDRESS) {
            require(premiumAmount <= msg.value, "RCPM: 1");
            IPremiumPool(premiumPool).addPremiumAmount{value: premiumAmount}(premiumCurrency, premiumAmount);
        } else {
            require(IERC20Upgradeable(premiumCurrency).balanceOf(msgSender) >= premiumAmount, "RCPM: 2");
            require(IERC20Upgradeable(premiumCurrency).allowance(msgSender, address(this)) >= premiumAmount, "RCPM: 3");
            IERC20Upgradeable(premiumCurrency).safeTransferFrom(msgSender, address(this), premiumAmount);
            IERC20Upgradeable(premiumCurrency).safeTransfer(premiumPool, premiumAmount);
            IPremiumPool(premiumPool).addPremiumAmount(premiumCurrency, premiumAmount);
        }
    }

    event UnlockCoverRewardEvent(address indexed owner, uint256 amount);

    function unlockRewardByController(address _owner, address _to) external override allowedCaller whenNotPaused nonReentrant returns (uint256) {
        return _unlockReward(_owner, _to);
    }

    function _unlockReward(address owner, address to) internal returns (uint256) {
        uint256 toBeunlockedAmt = ICoverData(data).getBuyCoverInsurTokenEarned(owner);
        if (toBeunlockedAmt > 0) {
            ICoverData(data).decreaseTotalInsurTokenRewardAmount(toBeunlockedAmt);
            ICoverData(data).decreaseBuyCoverInsurTokenEarned(owner, toBeunlockedAmt);
            IERC20Upgradeable(insur).safeTransfer(to, toBeunlockedAmt);
            emit UnlockCoverRewardEvent(owner, toBeunlockedAmt);
        }
        return toBeunlockedAmt;
    }

    function getRewardAmount() external view override returns (uint256) {
        return ICoverData(data).getBuyCoverInsurTokenEarned(_msgSender());
    }

    function getRewardAmountByStaker(address staker) external view override returns (uint256) {
        return ICoverData(data).getBuyCoverInsurTokenEarned(staker);
    }

    function getINSURRewardBalanceDetails() external view override returns (uint256, uint256) {
        uint256 insurRewardBalance = IERC20Upgradeable(insur).balanceOf(address(this));
        uint256 totalRewardRequired = ICoverData(data).getTotalInsurTokenRewardAmount();
        return (insurRewardBalance, totalRewardRequired);
    }

    function removeINSURRewardBalance(address toAddress, uint256 amount) external override onlyOwner {
        IERC20Upgradeable(insur).safeTransfer(toAddress, amount);
    }

    event SetBuyCoverMaxBlkNumLatencyEvent(uint256 numOfBlocks);

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external override onlyOwner {
        require(numOfBlocks > 0, "SBCMBNL: 1");
        buyCoverMaxBlkNumLatency = numOfBlocks;
        emit SetBuyCoverMaxBlkNumLatencyEvent(numOfBlocks);
    }

    event SetBuyCoverSignerEvent(address indexed signer, bool enabled);

    function setBuyCoverSigner(address signer, bool enabled) external override onlyOwner {
        require(signer != address(0), "SBCS: 1");
        buyCoverSignerFlagMap[signer] = enabled;
        emit SetBuyCoverSignerEvent(signer, enabled);
    }
}