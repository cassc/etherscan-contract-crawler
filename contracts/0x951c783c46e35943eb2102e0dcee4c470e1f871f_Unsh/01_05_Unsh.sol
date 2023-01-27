// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unshakable elements
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    Elements    //
//                //
//                //
////////////////////


contract Unsh is ERC1155Creator {
    constructor() ERC1155Creator("Unshakable elements", "Unsh") {}
}