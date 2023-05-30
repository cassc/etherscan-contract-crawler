// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luca's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//      __o           //
//     _<_\,_         //
//    (_)|'(_)        //
//                    //
//                    //
////////////////////////


contract LPE is ERC1155Creator {
    constructor() ERC1155Creator("Luca's Editions", "LPE") {}
}