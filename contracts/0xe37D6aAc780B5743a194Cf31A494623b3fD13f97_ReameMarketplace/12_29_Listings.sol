// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Listings {

    struct Listing
    {        
        uint256 listingId;
        address owner;
        uint256 tokenId;
        address acceptedToken;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    function paginate(
        Listing[] memory listings,
        uint256 page,
        uint256 limit) 
        internal pure returns (Listing[] memory result) 
    {
        result = new Listing[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= listings.length) {
                result[i] = Listing(0, address(0), 0, address(0), 0, 0, 0, false);
            } else {
                result[i] = listings[page * limit + i];
            }
        }
    }
}