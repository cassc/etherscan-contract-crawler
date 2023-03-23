//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

uint256 constant MAXIMUM_VALID_DURATION_IDX = 3;
uint256 constant MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX = 5;

uint256 constant STRIKE_PRICE_DECIMALS = 9;
uint256 constant MAXIMUM_STRIKE_PRICE = type(uint64).max;

library DataTypes {

    // Used to store nft availability and related call NFT. Here needs to consider data compression
    struct NFTStatusMap {
        // bit 0-1: maximumDurationIdx: value 0-3. 3 means the duration should be <= 28d. Default value is 3.
        // bit 2-4: minimumStrikeGapIdx: value 0-5. 1 means the strike price gap must be >= 10%. Default value is 1.
        // bit 5: NFT is on market
        // bit 6: reserved
        // bit 7: always be 1
        // bit 8-47: reserved
        // bit 48-87: exerciseTime
        // bit 88-127: endTime
        // bit 128-191: minimumStrikePrice
        // bit 192-255: strikePrice
        uint256 data;
        /* uint8 nftPreferenceMap;
        uint40 reserved;
        uint40 exerciseTime;
        uint40 endTime;
        uint64 minimumStrikePrice;
        uint64 strikePrice;*/
    }

    uint256 public constant NFT_STATUS_MAP_INIT_VALUE = 1 << 7;

    struct NFTStatusOutput {
        bool ifOnMarket;
        uint8 minimumStrikeGapIdx;
        uint8 maximumDurationIdx;
        uint256 exerciseTime;       // When can exercise
        uint256 endTime;            // When this call expire
        uint256 minimumStrikePrice;
        uint256 strikePrice;
    }
}