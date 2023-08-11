// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flavio Reber Chapters
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    love and inspiration    //
//                            //
//                            //
////////////////////////////////


contract FR is ERC1155Creator {
    constructor() ERC1155Creator("Flavio Reber Chapters", "FR") {}
}