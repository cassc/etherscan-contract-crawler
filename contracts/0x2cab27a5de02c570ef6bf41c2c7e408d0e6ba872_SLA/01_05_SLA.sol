// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slash
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    Water that can cut through everything.    //
//    A sword that can choose its master.       //
//    Slash that can pierce everything.         //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract SLA is ERC721Creator {
    constructor() ERC721Creator("Slash", "SLA") {}
}