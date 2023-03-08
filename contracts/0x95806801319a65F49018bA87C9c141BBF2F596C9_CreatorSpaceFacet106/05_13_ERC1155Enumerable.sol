// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1155EnumerableInternal} from "ERC1155EnumerableInternal.sol";

/**
 * @title ERC1155 implementation including enumerable and aggregate functions
 */
abstract contract ERC1155Enumerable is ERC1155EnumerableInternal {
    function totalSupply(uint256 id) internal view returns (uint256) {
        return _totalSupply(id);
    }
}
