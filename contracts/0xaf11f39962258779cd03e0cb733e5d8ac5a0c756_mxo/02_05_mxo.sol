// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mikko Raima
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Hello,friend.    //
//                     //
//    mx0              //
//                     //
//                     //
/////////////////////////


contract mxo is ERC1155Creator {
    constructor() ERC1155Creator("Mikko Raima", "mxo") {}
}