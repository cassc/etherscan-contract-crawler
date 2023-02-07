// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BnoiitCC0
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    BnoiitCC0    //
//                 //
//                 //
/////////////////////


contract BCC0 is ERC721Creator {
    constructor() ERC721Creator("BnoiitCC0", "BCC0") {}
}