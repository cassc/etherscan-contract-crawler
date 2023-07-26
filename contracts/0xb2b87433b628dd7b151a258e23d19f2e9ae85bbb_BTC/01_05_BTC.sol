// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beyond the Canvas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     _______  ________   ______      //
//    |       \|        \ /      \     //
//    | D$$$$$A\\A$$$$$$N|  $$$$$S\    //
//    | $$__/ $$  | $$   | $$   \$$    //
//    | $$    $$  | $$   | $$          //
//    | $$$$$$$\  | $$   | $$   __     //
//    | $$__/ $$  | $$   | $$__/  \    //
//    | $$    $$  | $$    \$$    $$    //
//     \$$$$$$$    \$$     \$$$$$$     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract BTC is ERC721Creator {
    constructor() ERC721Creator("Beyond the Canvas", "BTC") {}
}