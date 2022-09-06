// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heavens Production
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Heavens Production     //
//                           //
//                           //
///////////////////////////////


contract HP is ERC721Creator {
    constructor() ERC721Creator("Heavens Production", "HP") {}
}