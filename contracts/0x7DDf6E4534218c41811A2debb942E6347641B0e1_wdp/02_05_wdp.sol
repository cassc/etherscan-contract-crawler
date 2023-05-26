// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: watch dogs pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    watch_dogs    //
//                  //
//                  //
//////////////////////


contract wdp is ERC721Creator {
    constructor() ERC721Creator("watch dogs pass", "wdp") {}
}