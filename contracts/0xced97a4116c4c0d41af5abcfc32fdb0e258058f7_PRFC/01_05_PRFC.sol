// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purrfect Whiskers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    |\---/|    //
//    | o_o |    //
//     \_^_/     //
//               //
//               //
///////////////////


contract PRFC is ERC721Creator {
    constructor() ERC721Creator("Purrfect Whiskers", "PRFC") {}
}