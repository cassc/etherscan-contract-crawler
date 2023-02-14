// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Archive
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    The Archive, by Cod Mas.    //
//                                //
//                                //
////////////////////////////////////


contract ARCH is ERC721Creator {
    constructor() ERC721Creator("The Archive", "ARCH") {}
}