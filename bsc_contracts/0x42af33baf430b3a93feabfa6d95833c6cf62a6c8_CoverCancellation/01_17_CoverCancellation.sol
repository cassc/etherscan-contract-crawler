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

import "./02_17_SafeMathUpgradeable.sol";
import "./03_17_OwnableUpgradeable.sol";

import {ISecurityMatrix} from "./04_17_ISecurityMatrix.sol";
import {Math} from "./05_17_Math.sol";
import {Constant} from "./06_17_Constant.sol";
import {ICoverConfig} from "./07_17_ICoverConfig.sol";
import {ICoverData} from "./08_17_ICoverData.sol";
import {ICoverQuotation} from "./09_17_ICoverQuotation.sol";
import {IPremiumPool} from "./10_17_IPremiumPool.sol";
import {IExchangeRate} from "./11_17_IExchangeRate.sol";
import {ICoverCancellation} from "./12_17_ICoverCancellation.sol";
import {IReferralProgram} from "./13_17_IReferralProgram.sol";
import {CoverLib} from "./14_17_CoverLib.sol";

contract CoverCancellation is ICoverCancellation, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // the security matrix address
    address public smx;
    // the insur token address
    address public insur;
    // the cover data address
    address public data;
    // the cover config address
    address public cfg;
    // the exchange rate address
    address public exchangeRate;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setup(
        address _securityMatrixAddress,
        address _insurTokenAddress,
        address _coverDataAddress,
        address _coverCfgAddress,
        address _exchangeRate
    ) external onlyOwner {
        require(_securityMatrixAddress != address(0), "S:1");
        require(_insurTokenAddress != address(0), "S:2");
        require(_coverDataAddress != address(0), "S:3");
        require(_coverCfgAddress != address(0), "S:4");
        require(_exchangeRate != address(0), "S:5");
        smx = _securityMatrixAddress;
        insur = _insurTokenAddress;
        data = _coverDataAddress;
        cfg = _coverCfgAddress;
        exchangeRate = _exchangeRate;
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(smx).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    event CancelCoverEvent(address indexed owner, uint256 coverId, uint256 coverStatus, uint256 refundINSURAmount, uint256 feeINSURAmount);

    function cancelCover(address owner, uint256 coverId) external override allowedCaller returns (uint256) {
        uint256 coverStatus = ICoverData(data).getAdjustedCoverStatus(owner, coverId);
        require(coverStatus == Constant.COVERSTATUS_ACTIVE, "CCCV: 1");
        ICoverData(data).setCoverStatus(owner, coverId, Constant.COVERSTATUS_CANCELLED);

        uint256 refundINSURAmount = 0;
        uint256 feeINSURAmount = 0;
        (refundINSURAmount, feeINSURAmount) = _getINSURAmountDetails(owner, coverId);
        emit CancelCoverEvent(owner, coverId, Constant.COVERSTATUS_CANCELLED, refundINSURAmount, feeINSURAmount);

        uint256 oldEndTimestamp = ICoverData(data).getCoverEndTimestamp(owner, coverId);
        uint256 oldMaxClaimableTimestamp = ICoverData(data).getCoverMaxClaimableTimestamp(owner, coverId);
        ICoverData(data).setCoverEndTimestamp(owner, coverId, block.timestamp); // solhint-disable-line not-rely-on-time
        ICoverData(data).setCoverMaxClaimableTimestamp(owner, coverId, block.timestamp.add(oldMaxClaimableTimestamp).sub(oldEndTimestamp)); // solhint-disable-line not-rely-on-time

        return refundINSURAmount;
    }

    function getINSURAmountDetails(address owner, uint256 coverId) external view override returns (uint256, uint256) {
        return _getINSURAmountDetails(owner, coverId);
    }

    function _getINSURAmountDetails(address owner, uint256 coverId) internal view returns (uint256, uint256) {
        uint256 unearnedPremiumInINSURAmount = _getUnearnedPremiumInINSURAmount(owner, coverId);
        uint256 feeINSURAmount = unearnedPremiumInINSURAmount.mul(ICoverConfig(cfg).getCancelCoverFeeRateX10000()).div(10000);
        uint256 refundINSURAmount = unearnedPremiumInINSURAmount.sub(feeINSURAmount);
        return (refundINSURAmount, feeINSURAmount);
    }

    function _getUnearnedPremiumInINSURAmount(address owner, uint256 coverId) internal view returns (uint256) {
        address premiumCurrency = ICoverData(data).getCoverPremiumCurrency(owner, coverId);
        uint256 premiumAmount = ICoverData(data).getCoverEstimatedPremiumAmount(owner, coverId);
        uint256 unearnedPremiumAmount = CoverLib.getUnearnedPremiumAmount(data, owner, coverId, premiumAmount);
        return IExchangeRate(exchangeRate).getTokenToTokenAmount(premiumCurrency, insur, unearnedPremiumAmount);
    }
}