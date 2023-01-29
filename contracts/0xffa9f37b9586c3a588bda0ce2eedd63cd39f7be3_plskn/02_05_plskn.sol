// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pliskin.eth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    88""Yb 88     88 .dP"Y8 88  dP 88 88b 88     //
//    88__dP 88     88 `Ybo." 88odP  88 88Yb88     //
//    88"""  88  .o 88 o.`Y8b 88"Yb  88 88 Y88     //
//    88     88ood8 88 8bodP' 88  Yb 88 88  Y8     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract plskn is ERC1155Creator {
    constructor() ERC1155Creator("Pliskin.eth", "plskn") {}
}