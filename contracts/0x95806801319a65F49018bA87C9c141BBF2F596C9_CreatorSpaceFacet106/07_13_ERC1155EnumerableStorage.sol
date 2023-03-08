// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EnumerableSet} from "EnumerableSet.sol";

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("komon.contracts.storage.ERC1155Enumerable");

    function layout() internal pure returns (Layout storage lay) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lay.slot := slot
        }
    }
}
