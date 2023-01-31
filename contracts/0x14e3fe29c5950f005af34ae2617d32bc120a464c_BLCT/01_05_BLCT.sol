// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black cat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    Welcome to the land of one black cat                     //
//    Only 300 copies of the adorable cat will be available    //
//    With love Meow                                           //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract BLCT is ERC721Creator {
    constructor() ERC721Creator("Black cat", "BLCT") {}
}