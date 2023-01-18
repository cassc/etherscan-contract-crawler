// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SebOne Selection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    ----------    //
//                  //
//                  //
//////////////////////


contract SEB is ERC1155Creator {
    constructor() ERC1155Creator("SebOne Selection", "SEB") {}
}