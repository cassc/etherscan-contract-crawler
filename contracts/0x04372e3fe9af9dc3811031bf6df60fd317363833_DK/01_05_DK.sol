// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Decay photography
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    ___      ___    __   ____  __ __      //
//    |   \    /  _]  /  ] /    ||  |  |    //
//    |    \  /  [_  /  / |  o  ||  |  |    //
//    |  D  ||    _]/  /  |     ||  ~  |    //
//    |     ||   [_/   \_ |  _  ||___, |    //
//    |     ||     \     ||  |  ||     |    //
//    |_____||_____|\____||__|__||____/     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract DK is ERC1155Creator {
    constructor() ERC1155Creator("Decay photography", "DK") {}
}