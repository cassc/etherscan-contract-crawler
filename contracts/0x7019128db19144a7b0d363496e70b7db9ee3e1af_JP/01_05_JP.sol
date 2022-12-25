// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Jason Pundt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//         ,--.,------.      //
//         |  ||  .--. '     //
//    ,--. |  ||  '--' |     //
//    |  '-'  /|  | --'      //
//     `-----' `--'          //
//                           //
//                           //
//                           //
///////////////////////////////


contract JP is ERC1155Creator {
    constructor() ERC1155Creator("Editions by Jason Pundt", "JP") {}
}