// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dandy Bikeman Back Pain
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//     +-+-+-+-+ +-+-+-+-+    //
//     |B|a|c|k| |P|a|i|n|    //
//     +-+-+-+-+ +-+-+-+-+    //
//                            //
//                            //
////////////////////////////////


contract DBBP is ERC721Creator {
    constructor() ERC721Creator("Dandy Bikeman Back Pain", "DBBP") {}
}