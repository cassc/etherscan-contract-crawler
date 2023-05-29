// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: genPepes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    feels good man    //
//                      //
//                      //
//////////////////////////


contract genPepes is ERC1155Creator {
    constructor() ERC1155Creator("genPepes", "genPepes") {}
}