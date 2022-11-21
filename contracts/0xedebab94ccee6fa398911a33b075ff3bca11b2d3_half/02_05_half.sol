// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colored Halfthoughts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//      _                                              _                                            //
//     /    _   |   _   ._   _    _|    |_|   _.  |  _|_  _|_  |_    _         _   |_   _|_   _     //
//     \_  (_)  |  (_)  |   (/_  (_|    | |  (_|  |   |    |_  | |  (_)  |_|  (_|  | |   |_  _>     //
//                                                                             _|                   //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract half is ERC721Creator {
    constructor() ERC721Creator("Colored Halfthoughts", "half") {}
}