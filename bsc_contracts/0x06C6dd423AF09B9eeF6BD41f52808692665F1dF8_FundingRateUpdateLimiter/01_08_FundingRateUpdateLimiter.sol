/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../intf/IDealer.sol";
import "../intf/IPerpetual.sol";
import "../intf/IMarkPriceSource.sol";
import "../utils/SignedDecimalMath.sol";
import "../lib/Types.sol";

/// @notice Limiting funding rate change speed
/// Mainly for preventing JOJO's backend errors
/// and to prevent mischief
contract FundingRateUpdateLimiter is Ownable {
    using SignedDecimalMath for int256;

    // dealer
    address immutable dealer;
    // max speed multiplier, should be 1/2/3/4/5..., no decimal
    // funding rate max daily change will be limited to 
    // speedMultiplier*liquidationThreshold
    // e.d 3 * 3% = 9%
    uint8 immutable speedMultiplier;
    // The timestamp of the last funding rate update
    // used to limit the change rate of fundingRate
    mapping(address => uint256) public fundingRateUpdateTimestamp;

    constructor(address _dealer, uint8 _speedMultiplier) {
        dealer = _dealer;
        speedMultiplier = _speedMultiplier;
    }

    function updateFundingRate(
        address[] calldata perpList,
        int256[] calldata rateList
    ) external onlyOwner {
        for (uint256 i = 0; i < perpList.length; i++) {
            address perp = perpList[i];
            int256 oldRate = IPerpetual(perp).getFundingRate();
            uint256 maxChange = getMaxChange(perp);
            require(
                (rateList[i] - oldRate).abs() <= maxChange,
                "FUNDING_RATE_CHANGE_TOO_MUCH"
            );
            fundingRateUpdateTimestamp[perp] = block.timestamp;
        }

        IDealer(dealer).updateFundingRate(perpList, rateList);
    }

    // limit funding rate change speed
    // can not exceed speedMultiplier*liquidationThreshold
    function getMaxChange(address perp) public view returns (uint256) {
        Types.RiskParams memory params = IDealer(dealer).getRiskParams(perp);
        uint256 markPrice = IMarkPriceSource(params.markPriceSource)
            .getMarkPrice();
        uint256 timeInterval = block.timestamp -
            fundingRateUpdateTimestamp[perp];
        uint256 maxChangeRate = (speedMultiplier *
            timeInterval *
            params.liquidationThreshold) / (1 days);
        uint256 maxChange = (maxChangeRate * markPrice) / Types.ONE;
        return maxChange;
    }
}