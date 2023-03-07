// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EdgeStretching
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ███████ ██████   ██████  ███████ ████████     //
//    ██      ██   ██ ██       ██         ██        //
//    █████   ██   ██ ██   ███ ███████    ██        //
//    ██      ██   ██ ██    ██      ██    ██        //
//    ███████ ██████   ██████  ███████    ██        //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract EdgSt is ERC1155Creator {
    constructor() ERC1155Creator("EdgeStretching", "EdgSt") {}
}