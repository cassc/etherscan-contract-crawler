//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IFirstDibsMarketSettingsV2 {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
}