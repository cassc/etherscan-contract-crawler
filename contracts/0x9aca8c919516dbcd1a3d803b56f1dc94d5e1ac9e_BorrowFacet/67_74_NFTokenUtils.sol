// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {NFToken} from "../DataStructure/Objects.sol";

/// @notice Manipulates NFTs
library NFTokenUtils {
    /// @notice `a` is the the same NFT as `b`
    /// @return result
    function eq(NFToken memory a, NFToken memory b) internal pure returns (bool) {
        return (a.id == b.id && a.implem == b.implem);
    }
}