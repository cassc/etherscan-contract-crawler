// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ultrawide collages: inaugural
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    shit    //
//            //
//            //
////////////////


contract uwc is ERC721Creator {
    constructor() ERC721Creator("ultrawide collages: inaugural", "uwc") {}
}