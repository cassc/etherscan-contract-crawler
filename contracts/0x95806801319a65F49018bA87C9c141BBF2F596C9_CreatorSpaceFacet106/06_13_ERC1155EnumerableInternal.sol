// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1155EnumerableStorage} from "ERC1155EnumerableStorage.sol";

/**
 * @title ERC1155Enumerable internal functions
 */
abstract contract ERC1155EnumerableInternal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function _totalSupply(uint256 id) internal view virtual returns (uint256) {
        return ERC1155EnumerableStorage.layout().totalSupply[id];
    }
}
