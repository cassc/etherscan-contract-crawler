// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Night Verses
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    👑 See the future in the past      //
//       __        __                    //
//         /\ \      /\ \                //
//        /  \ \    /  \ \               //
//       / /\ \ \  / /\ \ \              //
//      / / /\ \ \/ / /\ \ \             //
//     / / /__\_\/ / /__\_\ \            //
//    / / /______\/ /________\           //
//    \/_____________________/           //
//                                       //
//                                       //
///////////////////////////////////////////


contract NTV is ERC721Creator {
    constructor() ERC721Creator("Night Verses", "NTV") {}
}