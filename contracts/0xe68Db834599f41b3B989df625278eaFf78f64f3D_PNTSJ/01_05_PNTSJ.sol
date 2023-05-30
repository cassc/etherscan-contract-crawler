// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 🌹 PNT23 · SANT JORDI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//    80 65 78 79 84  70 76 79 82  183  83 65 78 84  74 79 82 68 73  50 48 50 51     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract PNTSJ is ERC1155Creator {
    constructor() ERC1155Creator(unicode"🌹 PNT23 · SANT JORDI", "PNTSJ") {}
}