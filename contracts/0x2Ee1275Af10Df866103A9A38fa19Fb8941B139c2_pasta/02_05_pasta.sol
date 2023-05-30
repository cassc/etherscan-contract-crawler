// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pastastore
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    Cartoonist, Free figuration, outsider art.    //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract pasta is ERC1155Creator {
    constructor() ERC1155Creator("Pastastore", "pasta") {}
}