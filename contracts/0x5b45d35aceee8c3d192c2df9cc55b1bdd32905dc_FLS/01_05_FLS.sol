// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FEELS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                       W  W    oo_         //
//        wWw   wWw   wWw(O)(O)  /  _)-<     //
//        (O)_  (O)_  (O)_ ||    \__ `.      //
//       .' __).' __).' __)| \      `. |     //
//      (  _) (  _) (  _)  |  `.    _| |     //
//       )/    `.__) `.__)(.-.__),-'   |     //
//      (                  `-'  (_..--'      //
//                                           //
//                                           //
///////////////////////////////////////////////


contract FLS is ERC1155Creator {
    constructor() ERC1155Creator("FEELS", "FLS") {}
}