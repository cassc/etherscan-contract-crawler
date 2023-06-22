// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rodrigo Cairo's Artwork
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    _________        .__                   //
//    \_   ___ \_____  |__|______  ____      //
//    /    \  \/\__  \ |  \_  __ \/  _ \     //
//    \     \____/ __ \|  ||  | \(  <_> )    //
//     \______  (____  /__||__|   \____/     //
//            \/     \/                      //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Cairo is ERC721Creator {
    constructor() ERC721Creator("Rodrigo Cairo's Artwork", "Cairo") {}
}