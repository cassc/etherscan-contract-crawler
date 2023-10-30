// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Where we met
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//                                          //
//    ,--.   ,--.,--.   ,--.,--.   ,--.     //
//    |  |   |  ||  |   |  ||   `.'   |     //
//    |  |.'.|  ||  |.'.|  ||  |'.'|  |     //
//    |   ,'.   ||   ,'.   ||  |   |  |     //
//    '--'   '--''--'   '--'`--'   `--'     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract WWM is ERC721Creator {
    constructor() ERC721Creator("Where we met", "WWM") {}
}