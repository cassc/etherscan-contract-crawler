// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Makes Eels of us All
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//             (    (         //
//             )\ ) )\ )      //
//     (   (  (()/((()/(      //
//     )\  )\  /(_))/(_))     //
//    ((_)((_)(_)) (_))       //
//    | __| __| |  / __|      //
//    | _|| _|| |__\__ \      //
//    |___|___|____|___/      //
//                            //
//                            //
////////////////////////////////


contract EELS is ERC721Creator {
    constructor() ERC721Creator("Life Makes Eels of us All", "EELS") {}
}