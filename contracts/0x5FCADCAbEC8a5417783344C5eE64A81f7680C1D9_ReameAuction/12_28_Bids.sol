// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Bids
{
    struct Bid
    {
        uint256 bidId;
        address owner;
        uint256 auctionId;
        address acceptedToken;
        uint256 price;
        uint256 timestamp;
    }

    function paginate(
        Bid[] memory bids,
        uint256 page,
        uint256 limit)
        internal pure returns (Bid[] memory result) 
    {
        result = new Bid[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= bids.length) {
                result[i] = Bid(0, address(0), 0, address(0), 0, 0);
            } else {
                result[i] = bids[page * limit + i];
            }
        }
    }
}