// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital Paintings
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    dank was here.    //
//                      //
//                      //
//////////////////////////


contract dank is ERC1155Creator {
    constructor() ERC1155Creator("Digital Paintings", "dank") {}
}