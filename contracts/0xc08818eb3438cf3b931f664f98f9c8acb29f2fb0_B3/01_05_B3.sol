// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brand3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//    Collection created to share the Web3 brands created by FLOC*.                                                             //
//                                                                                                                              //
//    Brand3 is a methodology for creating decentralized brands through participatory processes and community collaboration.    //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract B3 is ERC721Creator {
    constructor() ERC721Creator("Brand3", "B3") {}
}