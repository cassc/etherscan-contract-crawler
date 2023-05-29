// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3REAMS 1ESS 2WEET
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     _____   _______ _____      //
//    |     |_|     __|     \     //
//    |       |__     |  --  |    //
//    |_______|_______|_____/     //
//                                //
//                                //
//                                //
////////////////////////////////////


contract LSD is ERC721Creator {
    constructor() ERC721Creator("3REAMS 1ESS 2WEET", "LSD") {}
}