// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Auctions 
{
    struct Auction    
    {
        uint256 auctionId;
        address owner;
        uint256 tokenId;
        address acceptedToken;
        uint256 price;
        uint256 soldPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 step;
        bool active;
    }

    function paginate(
        Auction[] memory auctions,
        uint256 page,
        uint256 limit)
        internal pure returns (Auction[] memory result) 
    {
        result = new Auction[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= auctions.length) {
                result[i] = Auction(0, address(0), 0, address(0), 0, 0, 0, 0, 0, false);
            } else {
                result[i] = auctions[page * limit + i];
            }
        }
    }
}