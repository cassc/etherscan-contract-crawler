// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Women of Glitnir by Dy Mokomi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Women of Glitnir     //
//    by Dy Mokomi         //
//                         //
//                         //
/////////////////////////////


contract GLITNIR is ERC721Creator {
    constructor() ERC721Creator("Women of Glitnir by Dy Mokomi", "GLITNIR") {}
}