// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BULLISH by FRIDGE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//    #   ______ _______ _____   _____   _______ _______ _______     //
//    #  |   __ \   |   |     |_|     |_|_     _|     __|   |   |    //
//    #  |   __ <   |   |       |       |_|   |_|__     |       |    //
//    #  |______/_______|_______|_______|_______|_______|___|___|    //
//    #                                                              //
//    The collection is a comic book consisting of 11 pages,         //
//    depicting a personified battle between bull and bear.          //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract BULL is ERC721Creator {
    constructor() ERC721Creator("BULLISH by FRIDGE", "BULL") {}
}