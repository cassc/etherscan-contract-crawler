// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LGND bitmap
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Believe in yourself    //
//                           //
//                           //
///////////////////////////////


contract lgnd is ERC1155Creator {
    constructor() ERC1155Creator("LGND bitmap", "lgnd") {}
}