// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct AuctionConfig {
    address auctionedNft;
    /**
     * @notice The number of auctions that can happen at the same time. For
     * example, if `lines == 3`, those will be the auctioned token ids over
     * time:
     *
     * --- TIME --->
     * 
     *  line 1: |--- 1 ---|---- 4 ----|--- 7 ---|---- 10 ---- ...
     *  line 2: |-- 2 --|----- 5 -----|-- 8 --|---- 11 ---- ...
     *  line 3: |---- 3 ----|-- 6 --|---- 9 ----|----- 12 ----- ...
     *
     * Then, from the front-end, you only need to call `lineToState[l].head`
     * to query the current auctioned nft at line `l`. For example, in the
     * graph above, `lineToState[2].head == 11`.
     */
    uint8 lines;
    // @notice The base duration is the time that takes a single auction
    // without considering time buffering.
    uint32 baseDuration;
    // @notice Extra auction time if a bid happens close to the auction end.
    uint32 timeBuffer;
    // @notice The minimum price accepted in an auction.
    uint96 startingPrice;
    // @notice The minimum bid increment.
    uint96 bidIncrement;
}

    
/**
 * @dev LineState represents a single auction line, so there will be
 * exactly `_auctionConfig.lines` LineStates.
 */
struct LineState {
    // @notice head Is the current auctioned token id at the line.
    uint24 head;
    uint40 startTime;
    uint40 endTime;
    address currentWinner;
    uint96 currentPrice;
}

interface IHoldsParallelAutoAuctionData {
    function auctionConfig() external view returns (AuctionConfig memory);
    /**
     * @return Current line state at `tokenId`, with data updated if the
     * auction for that line should get settled.
     */
    function lineState(uint24 tokenId) external view returns (LineState memory);
    /**
     * @return All `LineState`s.
     */
    function lineStates() external view returns (LineState[] memory);
}