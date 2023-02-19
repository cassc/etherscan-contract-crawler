// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reminiscence
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    .-,--.                                               //
//     `|__/ ,-. ,-,-. . ,-. . ,-. ,-. ,-. ,-. ,-. ,-.     //
//      | \  |-' | | | | | | | `-. |   |-' | | |   |-'     //
//    `-'  ` `-' ' ' ' ' ' ' ' `-' `-' `-' ' ' `-' `-'     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract RMNC is ERC721Creator {
    constructor() ERC721Creator("Reminiscence", "RMNC") {}
}