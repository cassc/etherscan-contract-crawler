// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: deliberare
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//        ____          //
//      /@    |__       //
//     |         O-<    //
//      \__.______/     //
//                      //
//                      //
//                      //
//                      //
//////////////////////////


contract dlbr is ERC1155Creator {
    constructor() ERC1155Creator("deliberare", "dlbr") {}
}