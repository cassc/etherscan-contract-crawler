// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pudgy !RIOT Order
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    Our time has come. The pudgy !riot order is here .. !RIOT    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract RIOT is ERC721Creator {
    constructor() ERC721Creator("Pudgy !RIOT Order", "RIOT") {}
}