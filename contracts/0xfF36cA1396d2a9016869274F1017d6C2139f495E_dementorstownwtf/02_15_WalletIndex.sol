// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title WalletIndex
 * @author @NiftyMike, NFT Culture
 * @dev Library that tracks an index against a wallet.
 *
 * Small helper library, in case you need to track a count by wallet.
 */
library WalletIndex {
    struct Index {
        // This variable should never be directly accessed by users of the library. See OZ comments in other libraries for more info.
        mapping(address => uint256) _index;
    }

    function _getNextIndex(Index storage index, address wallet) internal view returns (uint256) {
        return index._index[wallet];
    }

    function _incrementIndex(
        Index storage index,
        address wallet,
        uint256 count
    ) internal {
        index._index[wallet] += count;
    }
}