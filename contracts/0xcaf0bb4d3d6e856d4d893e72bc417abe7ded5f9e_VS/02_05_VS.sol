// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Void Sculptor
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Void Sculptor    //
//                     //
//                     //
/////////////////////////


contract VS is ERC721Creator {
    constructor() ERC721Creator("Void Sculptor", "VS") {}
}