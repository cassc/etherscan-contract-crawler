// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1989
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//     d888   .d8888b.   .d8888b.   .d8888b.      //
//    d8888  d88P  Y88b d88P  Y88b d88P  Y88b     //
//      888  888    888 Y88b. d88P 888    888     //
//      888  Y88b. d888  "Y88888"  Y88b. d888     //
//      888   "Y888P888 .d8P""Y8b.  "Y888P888     //
//      888         888 888    888        888     //
//      888  Y88b  d88P Y88b  d88P Y88b  d88P     //
//    8888888 "Y8888P"   "Y8888P"   "Y8888P"      //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract EG is ERC721Creator {
    constructor() ERC721Creator("1989", "EG") {}
}