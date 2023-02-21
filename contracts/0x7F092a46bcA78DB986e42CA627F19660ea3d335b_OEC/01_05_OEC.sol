// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opepen Edition Classic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    [Save the original Opepen Edition]    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract OEC is ERC721Creator {
    constructor() ERC721Creator("Opepen Edition Classic", "OEC") {}
}