// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ada Crow Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    Editions by Ada Crow minted on own smart contract via Manifold.    //
//                                                                       //
//    Art Historian & Surrealist artist                                  //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract ACE is ERC1155Creator {
    constructor() ERC1155Creator("Ada Crow Editions", "ACE") {}
}