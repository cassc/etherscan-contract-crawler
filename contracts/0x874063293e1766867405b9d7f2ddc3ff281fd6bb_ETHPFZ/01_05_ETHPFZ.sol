// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETHEREUM PUNKFRENZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//     _____    __ _  __          _           __ _  __   ___       //
//    |_  | |_||_ |_)|_ | ||V|   |_)| ||\||/ |_ |_)|_ |\| _/       //
//    |__ | | ||__| \|__|_|| |   |  |_|| ||\ |  | \|__| |/__       //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract ETHPFZ is ERC1155Creator {
    constructor() ERC1155Creator("ETHEREUM PUNKFRENZ", "ETHPFZ") {}
}