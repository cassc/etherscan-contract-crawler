// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pastel Dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Having Dreams in Pastel Colors.    //
//                                       //
//                                       //
///////////////////////////////////////////


contract PASTEL is ERC721Creator {
    constructor() ERC721Creator("Pastel Dreams", "PASTEL") {}
}