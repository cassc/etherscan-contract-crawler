// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tom Gerrard - Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    This is an offical NFT by Australian artist, Tom Gerrard.    //
//    Thanks for purchasing.                                       //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract TG is ERC1155Creator {
    constructor() ERC1155Creator("Tom Gerrard - Editions", "TG") {}
}