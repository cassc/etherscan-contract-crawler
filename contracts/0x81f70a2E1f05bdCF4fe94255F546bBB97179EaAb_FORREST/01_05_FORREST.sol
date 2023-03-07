// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Forrest Floor
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     _____________________      //
//    |                     |     //
//    |  ~ F 0 R R E S T    |     //
//    |        F L 0 0 R ~  |     //
//    |_____________________|     //
//                                //
//                                //
////////////////////////////////////


contract FORREST is ERC721Creator {
    constructor() ERC721Creator("Forrest Floor", "FORREST") {}
}