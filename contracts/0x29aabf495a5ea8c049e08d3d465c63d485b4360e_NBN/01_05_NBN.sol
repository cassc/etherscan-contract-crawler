// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Big NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    fnfbfn34    //
//                //
//                //
////////////////////


contract NBN is ERC721Creator {
    constructor() ERC721Creator("New Big NFT", "NBN") {}
}