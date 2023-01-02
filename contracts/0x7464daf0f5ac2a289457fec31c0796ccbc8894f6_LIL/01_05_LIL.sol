// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3dLyfer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    3dLyfer    //
//               //
//               //
///////////////////


contract LIL is ERC721Creator {
    constructor() ERC721Creator("3dLyfer", "LIL") {}
}