// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drawbot Open collec1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    8888b.  88""Yb  dP"Yb   dP""b8   .d     //
//     8I  Yb 88__dP dP   Yb dP   `" .d88     //
//     8I  dY 88""Yb Yb   dP Yb        88     //
//    8888Y"  88oodP  YbodP   YboodP   88     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract DBOC1 is ERC1155Creator {
    constructor() ERC1155Creator("Drawbot Open collec1", "DBOC1") {}
}