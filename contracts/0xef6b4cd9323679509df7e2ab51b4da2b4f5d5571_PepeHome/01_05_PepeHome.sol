// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Home
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    E.T. the past, Pepe has arrived    //
//                                       //
//                                       //
///////////////////////////////////////////


contract PepeHome is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Home", "PepeHome") {}
}