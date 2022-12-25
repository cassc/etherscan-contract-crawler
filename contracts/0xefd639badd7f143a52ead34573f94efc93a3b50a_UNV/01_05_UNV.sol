// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Universal Dreams
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    Ø    //
//         //
//         //
/////////////


contract UNV is ERC721Creator {
    constructor() ERC721Creator("Universal Dreams", "UNV") {}
}