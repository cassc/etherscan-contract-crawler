// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Living Rooms
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
//    .                            .--.                          //
//    |      o       o             |   )                         //
//    |      ..    ._.  .--. .-..  |--' .-.  .-. .--.--. .--.    //
//    |      | \  /  |  |  |(   |  |  \(   )(   )|  |  | `--.    //
//    '---'-' `-`' -' `-'  `-`-`|  '   ``-'  `-' '  '  `-`--'    //
//                           ._.'                                //
//                                               by AltArtist    //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract rooms is ERC721Creator {
    constructor() ERC721Creator("Living Rooms", "rooms") {}
}