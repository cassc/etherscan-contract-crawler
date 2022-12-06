// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Miscellaneous
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract MISC is ERC721Creator {
    constructor() ERC721Creator("Miscellaneous", "MISC") {}
}