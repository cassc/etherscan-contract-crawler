// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Station3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Station3    //
//                //
//                //
////////////////////


contract STATION3 is ERC721Creator {
    constructor() ERC721Creator("Station3", "STATION3") {}
}