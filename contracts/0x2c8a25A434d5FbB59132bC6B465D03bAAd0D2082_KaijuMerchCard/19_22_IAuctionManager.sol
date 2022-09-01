// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IAuctionManager {
    struct CreateAuction {
        uint104 reservePrice;
        uint16 winners;
        uint64 endsAt;
    }

    struct Auction {
        uint104 reservePrice;
        uint104 lowestWinningBid;
        uint16 winners;
        uint64 endsAt;
    }

    function get(uint256 id) external view returns (Auction memory);
    function getBid(uint256 id, address sender) external view returns (uint104);
    function isWinner(uint256 id, address sender) external view returns (bool);
    function create(uint256 id, CreateAuction calldata auction) external;
    function close(uint256 id, uint104 lowestWinningBid, address[] calldata _tiebrokenWinners) external;
    function bid(uint256 id, uint104 value, address sender) external returns (uint104);
    function settle(uint256 id, address sender) external returns (uint104);
}