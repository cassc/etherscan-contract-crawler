// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cazando Cielos – Editions Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    This contract will host all my editions drops.    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract CCE is ERC721Creator {
    constructor() ERC721Creator(unicode"Cazando Cielos – Editions Contract", "CCE") {}
}