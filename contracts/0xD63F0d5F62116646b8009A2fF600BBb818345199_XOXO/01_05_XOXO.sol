// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Love You.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    ██   ██  ██████  ██   ██  ██████      //
//     ██ ██  ██    ██  ██ ██  ██    ██     //
//      ███   ██    ██   ███   ██    ██     //
//     ██ ██  ██    ██  ██ ██  ██    ██     //
//    ██   ██  ██████  ██   ██  ██████      //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract XOXO is ERC1155Creator {
    constructor() ERC1155Creator("I Love You.", "XOXO") {}
}