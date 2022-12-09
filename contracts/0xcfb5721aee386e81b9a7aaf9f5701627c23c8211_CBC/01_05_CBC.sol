// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conflict of the burning church
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Location: Ghent                  //
//    Photographyer: Loïc Verhauwen    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract CBC is ERC721Creator {
    constructor() ERC721Creator("Conflict of the burning church", "CBC") {}
}