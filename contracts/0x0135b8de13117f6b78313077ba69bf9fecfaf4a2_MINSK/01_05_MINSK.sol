// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Studio Minsk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//                 //
//    M I N S K    //
//                 //
//                 //
//                 //
/////////////////////


contract MINSK is ERC1155Creator {
    constructor() ERC1155Creator("Studio Minsk", "MINSK") {}
}