// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUSION - by Mysterian
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"    //
//    "MMM███MMMM█████MMMM█████████████████MM"    //
//    "MMM████MM████M██MM██M██MMMMMMMM██MMMMM"    //
//    "MMM██M████M██MM████MM███████MMM██MMMMM"    //
//    "MMM██MM██MM██MMM██MMMMMMMM██MMM██MMMMM"    //
//    "MMM██MMMMMM██MMM██MMM███████MMM██MMMMM"    //
//    "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract FUSE is ERC721Creator {
    constructor() ERC721Creator("FUSION - by Mysterian", "FUSE") {}
}