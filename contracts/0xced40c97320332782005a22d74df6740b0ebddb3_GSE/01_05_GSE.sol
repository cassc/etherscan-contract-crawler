// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghoste Stories Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Booooooooooooooooo    //
//                          //
//                          //
//////////////////////////////


contract GSE is ERC1155Creator {
    constructor() ERC1155Creator("Ghoste Stories Editions", "GSE") {}
}