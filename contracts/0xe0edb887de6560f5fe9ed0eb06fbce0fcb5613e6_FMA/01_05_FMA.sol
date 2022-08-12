// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Follow Me Away
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//     __                                  __    __         __          //
//    |    >>  |   |    >>  |   |   |\ /| |     |  | |   | |  | | |     //
//    |<< |  | |   |   |  | | < |   | < | |<<   |><| | < | |><| \</     //
//    |    <<  |<< |<<  <<  |/ \|   |   | |__   |  | |/ \| |  |  |      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract FMA is ERC721Creator {
    constructor() ERC721Creator("Follow Me Away", "FMA") {}
}