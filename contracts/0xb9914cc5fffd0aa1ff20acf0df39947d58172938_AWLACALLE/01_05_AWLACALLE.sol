// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alex Webb: La Calle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    La Calle by Alex Webb    //
//                             //
//                             //
/////////////////////////////////


contract AWLACALLE is ERC721Creator {
    constructor() ERC721Creator("Alex Webb: La Calle", "AWLACALLE") {}
}