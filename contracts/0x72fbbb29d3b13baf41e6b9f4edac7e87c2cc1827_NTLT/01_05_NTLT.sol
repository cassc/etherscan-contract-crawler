// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naturlichturism Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    nat. ed.    //
//                //
//                //
////////////////////


contract NTLT is ERC1155Creator {
    constructor() ERC1155Creator("Naturlichturism Editions", "NTLT") {}
}