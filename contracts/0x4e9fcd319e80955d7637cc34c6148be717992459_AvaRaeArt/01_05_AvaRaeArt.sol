// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ava's Swirly Creation #8 (Butterfly)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//    Ava's Swirly Creation #8 (Butterfly) has 1000 editions at .0008 ETH. The goal is to build her funds to eventually create her first childrens book.    //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AvaRaeArt is ERC1155Creator {
    constructor() ERC1155Creator("Ava's Swirly Creation #8 (Butterfly)", "AvaRaeArt") {}
}