// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Queria Ter Nascido Artista Herdeiro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    Arte por Lucas Ururah em parceria com Studio Krya      //
//                                                           //
//    Art by Lucas Ururah in partnership with Studio Krya    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract QTNAH is ERC721Creator {
    constructor() ERC721Creator("Queria Ter Nascido Artista Herdeiro", "QTNAH") {}
}