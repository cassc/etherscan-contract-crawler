// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Awakening Ordinals
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    //-\ \\/\\/ //-\ ][< ]E ][\][ ]][ ][\][ ((6    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract AOBTC is ERC721Creator {
    constructor() ERC721Creator("Awakening Ordinals", "AOBTC") {}
}