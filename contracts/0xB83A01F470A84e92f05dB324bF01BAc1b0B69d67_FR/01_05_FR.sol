// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flavio Reber Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    love and inspiration    //
//                            //
//                            //
////////////////////////////////


contract FR is ERC721Creator {
    constructor() ERC721Creator("Flavio Reber Editions", "FR") {}
}