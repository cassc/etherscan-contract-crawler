// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Project T.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    RizArt    //
//              //
//              //
//////////////////


contract RizArt is ERC1155Creator {
    constructor() ERC1155Creator("Project T.", "RizArt") {}
}