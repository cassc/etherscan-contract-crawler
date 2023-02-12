// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Offers {

    struct Offer
    {
        uint256 offerId;
        address owner;
        uint256 tokenId;
        address acceptedToken;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    function paginate(
        Offer[] memory offers,
        uint256 page,
        uint256 limit) 
        internal pure returns (Offer[] memory result) 
    {
        result = new Offer[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= offers.length) {
                result[i] = Offer(0, address(0), 0, address(0), 0, 0, 0, false);
            } else {
                result[i] = offers[page * limit + i];
            }
        }
    }
}