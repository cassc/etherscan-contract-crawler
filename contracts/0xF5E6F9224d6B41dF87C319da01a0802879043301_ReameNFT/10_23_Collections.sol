// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Collections 
{
    struct Collection
    {
        uint256 collectionId;
        address owner;
    }

    function paginate(
        Collection[] memory collections,
        uint256 page,
        uint256 limit)
        internal pure returns (Collection[] memory result) 
    {
        result = new Collection[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= collections.length) {
                result[i] = Collection(0, address(0));
            } else {
                result[i] = collections[page * limit + i];
            }
        }
    }
}