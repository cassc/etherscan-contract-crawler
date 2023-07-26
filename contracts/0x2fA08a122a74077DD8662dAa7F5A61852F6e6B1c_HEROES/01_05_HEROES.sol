// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Heroes Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    The Heroes Collection    //
//                             //
//                             //
/////////////////////////////////


contract HEROES is ERC721Creator {
    constructor() ERC721Creator("The Heroes Collection", "HEROES") {}
}