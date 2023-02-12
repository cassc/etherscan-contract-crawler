// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Uint256Pagination {
    function paginate(
        uint256[] memory ids,
        uint256 page,
        uint256 limit
    ) internal pure returns (uint256[] memory result) {
        result = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= ids.length) {
                result[i] = 0;
            } else {
                result[i] = ids[page * limit + i];
            }
        }
    }
}