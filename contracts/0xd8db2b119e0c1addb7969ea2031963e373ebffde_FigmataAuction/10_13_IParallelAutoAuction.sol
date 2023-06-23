// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IEthAuction.sol";
import "./IHoldsParallelAutoAuctionData.sol";

interface IParallelAutoAuction is IEthAuction, IHoldsParallelAutoAuctionData {
    
    event Bid(uint24 indexed tokenId, address bidder, uint256 value);
    event Won(uint24 indexed tokenId, address bidder, uint256 value);

    /**
     * @dev This method lets a `nftId` winner to claim it after an aunction ends,
     * It can also be used to claim the last auctioned `nftIds`s. Note that this
     * has to do with the original `BonklerAuction` contract, which automatically
     * settles auction when the auction for the next `nftId` starts.
     */
    function settleAuction(uint24 nftId) external;
}