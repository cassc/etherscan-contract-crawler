// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LADY Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    L    //
//    A    //
//    D    //
//    Y    //
//         //
//         //
/////////////


contract LADY is ERC721Creator {
    constructor() ERC721Creator("LADY Collection", "LADY") {}
}