// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: c0des 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//             \      |              _ |    / _ |          //
//       _|  (  |  _` |   -_) (_-<     |   /    | (_-<     //
//     \__| \__/ \__,_| \___| ___/    _| _/    _| ___/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract CDS is ERC721Creator {
    constructor() ERC721Creator("c0des 1/1s", "CDS") {}
}