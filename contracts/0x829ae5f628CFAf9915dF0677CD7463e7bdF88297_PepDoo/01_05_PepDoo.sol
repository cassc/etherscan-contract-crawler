// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Doohickeys
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                                                                       //
//    ██████  ███████ ██████  ███████                                    //
//    ██   ██ ██      ██   ██ ██                                         //
//    ██████  █████   ██████  █████                                      //
//    ██      ██      ██      ██                                         //
//    ██      ███████ ██      ███████                                    //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract PepDoo is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Doohickeys", "PepDoo") {}
}