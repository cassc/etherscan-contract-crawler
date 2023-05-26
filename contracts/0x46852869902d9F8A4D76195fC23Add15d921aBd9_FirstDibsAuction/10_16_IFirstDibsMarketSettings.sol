//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;

interface IFirstDibsMarketSettings {
    function globalBuyerPremium() external view returns (uint32);

    function globalMarketCommission() external view returns (uint32);

    function globalCreatorRoyaltyRate() external view returns (uint32);

    function globalMinimumBidIncrement() external view returns (uint32);

    function globalTimeBuffer() external view returns (uint32);

    function globalAuctionDuration() external view returns (uint32);

    function commissionAddress() external view returns (address);
}