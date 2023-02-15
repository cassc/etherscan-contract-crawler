// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trade Pass NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    fnfbfn06    //
//                //
//                //
////////////////////


contract TPN is ERC721Creator {
    constructor() ERC721Creator("Trade Pass NFT", "TPN") {}
}