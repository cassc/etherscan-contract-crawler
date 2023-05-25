// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRoyaltyInternal.sol";
import "./IRoyalty.sol";

library RoyaltyStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Layout {
        IRoyaltyInternal.TokenRoyalty defaultRoyalty;
        mapping(uint256 => IRoyaltyInternal.TokenRoyalty) tokenRoyalties;
        EnumerableSet.UintSet tokensWithRoyalties;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.Royalty");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}