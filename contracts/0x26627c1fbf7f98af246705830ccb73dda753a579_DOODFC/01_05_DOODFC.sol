// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fashion Check
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Fashion Check Open Edition    //
//                                  //
//                                  //
//////////////////////////////////////


contract DOODFC is ERC721Creator {
    constructor() ERC721Creator("Fashion Check", "DOODFC") {}
}