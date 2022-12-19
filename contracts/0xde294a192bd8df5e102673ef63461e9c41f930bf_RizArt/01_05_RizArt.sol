// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Project T.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Project T.    //
//                  //
//                  //
//////////////////////


contract RizArt is ERC721Creator {
    constructor() ERC721Creator("Project T.", "RizArt") {}
}