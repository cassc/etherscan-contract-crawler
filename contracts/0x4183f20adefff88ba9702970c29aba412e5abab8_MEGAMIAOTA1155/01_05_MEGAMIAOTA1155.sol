// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEGAMI CARD BY Aotakana
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    MEGAMIAOTA1155    //
//                      //
//                      //
//////////////////////////


contract MEGAMIAOTA1155 is ERC1155Creator {
    constructor() ERC1155Creator("MEGAMI CARD BY Aotakana", "MEGAMIAOTA1155") {}
}