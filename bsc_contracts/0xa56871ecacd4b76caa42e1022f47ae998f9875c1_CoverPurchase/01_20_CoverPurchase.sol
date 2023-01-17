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

import "./02_20_SafeMathUpgradeable.sol";
import "./03_20_OwnableUpgradeable.sol";

import {ISecurityMatrix} from "./04_20_ISecurityMatrix.sol";
import {Math} from "./05_20_Math.sol";
import {Constant} from "./06_20_Constant.sol";
import {ICoverConfig} from "./07_20_ICoverConfig.sol";
import {ICoverData} from "./08_20_ICoverData.sol";
import {ICoverQuotation} from "./09_20_ICoverQuotation.sol";
import {ICoverQuotationData} from "./10_20_ICoverQuotationData.sol";
import {ICapitalPool} from "./11_20_ICapitalPool.sol";
import {IPremiumPool} from "./12_20_IPremiumPool.sol";
import {IExchangeRate} from "./13_20_IExchangeRate.sol";
import {IReferralProgram} from "./14_20_IReferralProgram.sol";
import {ICoverPurchase} from "./15_20_ICoverPurchase.sol";
import {IProduct} from "./16_20_IProduct.sol";
import {CoverLib} from "./17_20_CoverLib.sol";

contract CoverPurchase is ICoverPurchase, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // the security matrix address
    address public smx;
    // the insur token address
    address public insur;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the cover quotation address
    address public quotation;
    // the cover quotation data address
    address public quotationData;
    // the exchange rate address
    address public exchangeRate;
    // the referral program address
    address public referralProgram;
    // the product address
    address public product;

    // the overall capacity currency (e.g. USDT)
    address public capacityCurrency;
    // the overall capacity available amount (e.g. 10mil)
    uint256 public capacityAvailableAmount;
    // the number of blocks window size (e.g. 600 blocks)
    uint256 public capacityNumOfBlocksWindowSize;
    // the last window start block number
    uint256 public lastWindowStartBlockNumber;
    // the last window sold capacity amount
    uint256 public lastWindowSoldCapacityAmount;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setup(
        address _securityMatrix,
        address _insurToken,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _coverQuotationAddress,
        address _coverQuotationDataAddress,
        address _productAddress,
        address _exchangeRate,
        address _referralProgram
    ) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        require(_insurToken != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_coverQuotationAddress != address(0), "S:5");
        require(_coverQuotationDataAddress != address(0), "S:6");
        require(_productAddress != address(0), "S:7");
        require(_exchangeRate != address(0), "S:8");
        require(_referralProgram != address(0), "S:9");
        smx = _securityMatrix;
        insur = _insurToken;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        quotation = _coverQuotationAddress;
        quotationData = _coverQuotationDataAddress;
        product = _productAddress;
        exchangeRate = _exchangeRate;
        referralProgram = _referralProgram;
    }

    event SetOverallCapacityEvent(address indexed _currency, uint256 _availableAmount, uint256 _numOfBlocksWindowSize);

    function setOverallCapacity(
        address _currency,
        uint256 _availableAmount,
        uint256 _numOfBlocksWindowSize
    ) external override onlyOwner {
        capacityCurrency = _currency;
        capacityAvailableAmount = _availableAmount;
        capacityNumOfBlocksWindowSize = _numOfBlocksWindowSize;
        emit SetOverallCapacityEvent(_currency, _availableAmount, _numOfBlocksWindowSize);
    }

    function getOverallCapacity()
        external
        view
        override
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (capacityCurrency, capacityAvailableAmount, capacityNumOfBlocksWindowSize);
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    function prepareBuyCover(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        uint256[] memory usedAmounts,
        uint256[] memory totalAmounts,
        uint256 allTotalAmount,
        address[] memory currencies,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        override
        returns (
            uint256 premiumAmount,
            uint256[] memory helperParameters,
            uint256 discountPercentX10000,
            uint256[] memory insurRewardAmounts
        )
    {
        require(products.length == durationInDays.length, "GPCHK: 1");
        require(products.length == amounts.length, "GPCHK: 2");
        require(ICoverConfig(cfg).isValidCurrency(currencies[0]) && ICoverConfig(cfg).isValidCurrency(currencies[1]), "GPCHK: 3");
        require(owner != address(0), "GPCHK: 4");
        require(address(uint160(referralCode)) != address(0), "GPCHK: 5");

        // calculate total amounts and total weights
        helperParameters = new uint256[](2);
        for (uint256 i = 0; i < products.length; i++) {
            uint256 productId = products[i];
            uint256 coverDuration = durationInDays[i];
            uint256 coverAmount = amounts[i];
            helperParameters[0] = helperParameters[0].add(coverAmount);
            helperParameters[1] = helperParameters[1].add(coverAmount.mul(coverDuration).mul(ICoverQuotationData(quotationData).getUnitCost(productId)));
        }

        // calculate the cover premium amount
        (premiumAmount, discountPercentX10000) = ICoverQuotation(quotation).getPremium(products, durationInDays, amounts, usedAmounts, totalAmounts, allTotalAmount, currencies[0]);
        premiumAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[0], currencies[1], premiumAmount);
        require(premiumAmount > 0, "GPCHK: 6");

        // calculate the cover owner and referral INSUR reward amounts
        require(rewardPercentages.length == 2, "GPCHK: 7");
        insurRewardAmounts = new uint256[](2);
        uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[1], insur, premiumAmount);
        if (premiumAmount2Insur > 0 && owner != address(uint160(referralCode))) {
            // calculate the Cover Owner INSUR Reward Amount
            uint256 coverOwnerRewardPctg = CoverLib.getRewardPctg(cfg, rewardPercentages[0]);
            insurRewardAmounts[0] = CoverLib.getRewardAmount(premiumAmount2Insur, coverOwnerRewardPctg);
            // calculate the Referral INSUR Reward Amount
            uint256 referralRewardPctg = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, rewardPercentages[1]);
            insurRewardAmounts[1] = IReferralProgram(referralProgram).getRewardAmount(Constant.REFERRALREWARD_COVER, premiumAmount2Insur, referralRewardPctg);
        }

        // check the overall capacity
        if (capacityCurrency != address(0)) {
            uint256 occuipedCapacityAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(currencies[0], capacityCurrency, helperParameters[0]);
            uint256 totalOccupiedCapacityAmount = capacityNumOfBlocksWindowSize.add(lastWindowStartBlockNumber) <= block.number ? occuipedCapacityAmount : occuipedCapacityAmount.add(lastWindowSoldCapacityAmount);
            require(totalOccupiedCapacityAmount <= capacityAvailableAmount, "GPCHK: 8");
        }

        return (premiumAmount, helperParameters, discountPercentX10000, insurRewardAmounts);
    }

    event BuyCoverEventV3(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, address indexed premiumCurrency, uint256 estimatedPremiumAmount, uint256 coverStatus, uint256 delayEffectiveDays);

    event BuyCoverEventV4(address indexed currency, address indexed owner, uint256 coverId, uint256 productId, uint256 durationInDays, uint256 extendedClaimDays, uint256 coverAmount, address indexed premiumCurrency, uint256 estimatedPremiumAmount, uint256 coverStatus, uint256 delayEffectiveDays, string freeText);

    event BuyCoverOwnerRewardEventV2(address indexed owner, uint256 rewardPctg, uint256 insurRewardAmt);

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        string memory freeText
    ) external override allowedCaller {
        // check and update the overall capacity amount
        if (capacityCurrency != address(0)) {
            uint256 occuipedCapacityAmount = IExchangeRate(exchangeRate).getTokenToTokenAmount(addresses[1], capacityCurrency, helperParameters[0]);
            if (capacityNumOfBlocksWindowSize.add(lastWindowStartBlockNumber) <= block.number) {
                lastWindowStartBlockNumber = block.number;
                lastWindowSoldCapacityAmount = occuipedCapacityAmount;
            } else {
                lastWindowSoldCapacityAmount = lastWindowSoldCapacityAmount.add(occuipedCapacityAmount);
            }
            require(lastWindowSoldCapacityAmount <= capacityAvailableAmount, "CPBC: 1");
        }
        // check and get the reward percentages if there is a valid referral code
        uint256[] memory rewardPctgs = new uint256[](2);
        if (addresses[0] != address(uint160(referralCode))) {
            uint256 premiumAmount2Insur = IExchangeRate(exchangeRate).getTokenToTokenAmount(addresses[2], insur, premiumAmount);
            // distribute the cover owner reward
            rewardPctgs[0] = CoverLib.getRewardPctg(cfg, helperParameters[2]);
            uint256 ownerRewardAmount = CoverLib.processCoverOwnerReward(data, addresses[0], premiumAmount2Insur, rewardPctgs[0]);
            emit BuyCoverOwnerRewardEventV2(addresses[0], rewardPctgs[0], ownerRewardAmount);
            // distribute the referral reward if the referral address is not the owner address
            rewardPctgs[1] = IReferralProgram(referralProgram).getRewardPctg(Constant.REFERRALREWARD_COVER, helperParameters[3]);
            IReferralProgram(referralProgram).processReferralReward(address(uint160(referralCode)), addresses[0], Constant.REFERRALREWARD_COVER, premiumAmount2Insur, rewardPctgs[1]);
        }
        // create the expanded cover records (one per each cover item)
        _createCovers(products, durationInDays, amounts, addresses, premiumAmount, helperParameters, freeText, rewardPctgs);
    }

    function _createCovers(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        string memory freeText,
        uint256[] memory rewardPctgs
    ) internal {
        uint256 cumPremiumAmount = 0;
        for (uint256 index = 0; index < products.length; ++index) {
            uint256 estimatedPremiumAmount = 0;
            if (index == products.length.sub(1)) {
                estimatedPremiumAmount = premiumAmount.sub(cumPremiumAmount);
            } else {
                uint256 currentWeight = amounts[index].mul(durationInDays[index]).mul(ICoverQuotationData(quotationData).getUnitCost(products[index]));
                estimatedPremiumAmount = premiumAmount.mul(currentWeight).div(helperParameters[1]);
                cumPremiumAmount = cumPremiumAmount.add(estimatedPremiumAmount);
            }
            _createOneCover(products[index], durationInDays[index], amounts[index], addresses, estimatedPremiumAmount, freeText, rewardPctgs);
        }
    }

    function _createOneCover(
        uint256 productId,
        uint256 durationInDays,
        uint256 amount,
        address[] memory addresses,
        uint256 estimatedPremiumAmount,
        string memory freeText,
        uint256[] memory rewardPctgs
    ) internal {
        uint256 nextCoverId = ICoverData(data).increaseCoverCount(addresses[0]);
        {
            uint256 beginTimestamp = block.timestamp.add(IProduct(product).getProductDelayEffectiveDays(productId) * 1 days); // solhint-disable-line not-rely-on-time
            uint256 endTimestamp = beginTimestamp.add(durationInDays * 1 days);
            ICoverData(data).setNewCoverDetails(addresses[0], nextCoverId, productId, amount, addresses[1], addresses[2], estimatedPremiumAmount, beginTimestamp, endTimestamp, endTimestamp.add(ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired() * 1 days), Constant.COVERSTATUS_ACTIVE);
        }

        if (bytes(freeText).length > 0) {
            ICoverData(data).setCoverFreeText(addresses[0], nextCoverId, freeText);
        }

        if (rewardPctgs[0] > 0) {
            ICoverData(data).setCoverRewardPctg(addresses[0], nextCoverId, rewardPctgs[0]);
        }

        if (rewardPctgs[1] > 0) {
            ICoverData(data).setCoverReferralRewardPctg(addresses[0], nextCoverId, rewardPctgs[1]);
        }

        uint256 delayEffectiveDays = IProduct(product).getProductDelayEffectiveDays(productId);
        emit BuyCoverEventV4(addresses[1], addresses[0], nextCoverId, productId, durationInDays, ICoverConfig(cfg).getMaxClaimDurationInDaysAfterExpired(), amount, addresses[2], estimatedPremiumAmount, Constant.COVERSTATUS_ACTIVE, delayEffectiveDays, freeText);
    }
}