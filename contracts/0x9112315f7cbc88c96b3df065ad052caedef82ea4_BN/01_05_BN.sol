// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRUTALNODE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//         []  ,----.___       //
//       __||_/___      '.     //
//      / O||    /|       )    //
//     /   ""   / /   =._/     //
//    /________/ /             //
//    |________|/   dew        //
//                             //
//                             //
/////////////////////////////////


contract BN is ERC1155Creator {
    constructor() ERC1155Creator("BRUTALNODE", "BN") {}
}