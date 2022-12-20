// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frope's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Frope's Editions    //
//                        //
//                        //
////////////////////////////


contract FRP is ERC1155Creator {
    constructor() ERC1155Creator("Frope's Editions", "FRP") {}
}