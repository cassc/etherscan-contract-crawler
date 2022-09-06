// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC0 Remixes [XCOPY, REKTGUY, PEPE, ...]
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    Remix 0f top glitch artist's CC0 artworks ...    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract CC0 is ERC721Creator {
    constructor() ERC721Creator("CC0 Remixes [XCOPY, REKTGUY, PEPE, ...]", "CC0") {}
}