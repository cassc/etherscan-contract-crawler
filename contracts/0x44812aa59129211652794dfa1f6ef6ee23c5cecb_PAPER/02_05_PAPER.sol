// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collages
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//               _                //
//     ___  __ _| |_   _____      //
//    / __|/ _` | \ \ / / _ \     //
//    \__ \ (_| | |\ V / (_) |    //
//    |___/\__,_|_| \_/ \___/     //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract PAPER is ERC721Creator {
    constructor() ERC721Creator("Collages", "PAPER") {}
}