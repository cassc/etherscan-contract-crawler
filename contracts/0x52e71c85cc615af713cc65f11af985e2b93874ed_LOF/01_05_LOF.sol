// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light or Flight
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//    ██████       ██████       █████      ██████                                                                         //
//    ██   ██     ██    ██     ██   ██     ██   ██                                                                        //
//    ██████      ██    ██     ███████     ██████                                                                         //
//    ██          ██    ██     ██   ██     ██                                                                             //
//    ██           ██████      ██   ██     ██                                                                             //
//                                                                                                                        //
//                                                                                                                        //
//    ERC721 - HDONNITHORNE-TAIT - hdt.eth - LIGHT OR FLIGHT.com                                                          //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOF is ERC721Creator {
    constructor() ERC721Creator("Light or Flight", "LOF") {}
}