// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

}