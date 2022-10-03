// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SteamPunk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    SteamPunk    //
//                 //
//                 //
/////////////////////


contract SP is ERC721Creator {
    constructor() ERC721Creator("SteamPunk", "SP") {}
}