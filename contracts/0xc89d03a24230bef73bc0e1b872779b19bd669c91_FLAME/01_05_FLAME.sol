// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fireside Series 0001
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    fire (U+1F525)    //
//                      //
//                      //
//////////////////////////


contract FLAME is ERC1155Creator {
    constructor() ERC1155Creator("Fireside Series 0001", "FLAME") {}
}