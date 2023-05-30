// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IZZ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    This might be izzakko    //
//                             //
//                             //
/////////////////////////////////


contract AKKO is ERC721Creator {
    constructor() ERC721Creator("IZZ", "AKKO") {}
}