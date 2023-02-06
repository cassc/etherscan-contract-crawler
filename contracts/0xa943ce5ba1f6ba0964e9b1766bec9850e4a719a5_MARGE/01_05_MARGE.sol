// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARGΞ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    _    //
//    _    //
//    _    //
//         //
//         //
/////////////


contract MARGE is ERC1155Creator {
    constructor() ERC1155Creator(unicode"MARGΞ", "MARGE") {}
}