// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dbc
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//     _______  .______     ______     //
//    |       \ |   _  \   /      |    //
//    |  .--.  ||  |_)  | |  ,----'    //
//    |  |  |  ||   _  <  |  |         //
//    |  '--'  ||  |_)  | |  `----.    //
//    |_______/ |______/   \______|    //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract dbc is ERC721Creator {
    constructor() ERC721Creator("dbc", "dbc") {}
}