// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vivi Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Vivi Editions    //
//                     //
//                     //
/////////////////////////


contract ViviE is ERC1155Creator {
    constructor() ERC1155Creator("Vivi Editions", "ViviE") {}
}