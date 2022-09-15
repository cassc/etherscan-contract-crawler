// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grillzilla
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       ___      _ _ _     _ _ _           //
//      / _ \_ __(_) | |___(_) | | __ _     //
//     / /_\/ '__| | | |_  / | | |/ _` |    //
//    / /_\\| |  | | | |/ /| | | | (_| |    //
//    \____/|_|  |_|_|_/___|_|_|_|\__,_|    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract GZILLA is ERC721Creator {
    constructor() ERC721Creator("Grillzilla", "GZILLA") {}
}