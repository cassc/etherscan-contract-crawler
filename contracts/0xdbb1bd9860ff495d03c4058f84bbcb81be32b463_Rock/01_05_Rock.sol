// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Galaxy Rocks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Galaxy Rocks on the Blockchain    //
//                                      //
//                                      //
//////////////////////////////////////////


contract Rock is ERC1155Creator {
    constructor() ERC1155Creator("Galaxy Rocks", "Rock") {}
}