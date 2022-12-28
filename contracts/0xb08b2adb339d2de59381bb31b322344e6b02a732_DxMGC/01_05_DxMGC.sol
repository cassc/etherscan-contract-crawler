// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doors x Mauro
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    DOORS <> PORTALS <> DOORS    //
//                                 //
//                                 //
/////////////////////////////////////


contract DxMGC is ERC721Creator {
    constructor() ERC721Creator("Doors x Mauro", "DxMGC") {}
}