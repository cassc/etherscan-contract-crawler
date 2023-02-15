// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amine Be Romdhane Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    Amine Be Romdhane - landscape photography    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract ABRE is ERC1155Creator {
    constructor() ERC1155Creator("Amine Be Romdhane Editions", "ABRE") {}
}