// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PROROK EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    █▀▄ ██▀ ▄▀▄ █                     //
//    █▀▄ █▄▄ █▀█ █▄▄                   //
//                                      //
//    █▀▄ █▀▄ ▄▀▄ █▀▄ ▄▀▄ █▄▀           //
//    █▀  █▀▄ ▀▄▀ █▀▄ ▀▄▀ █ █           //
//                                      //
//    ██▀ █▀▄ █ ▀█▀ █ ▄▀▄ █▄ █ ▄▀▀ █    //
//    █▄▄ █▄▀ █  █  █ ▀▄▀ █ ▀█ ▄██ ▄    //
//                                      //
//    ______________ from Prorok.eth    //
//                                      //
//                                      //
//////////////////////////////////////////


contract PROROK is ERC1155Creator {
    constructor() ERC1155Creator("PROROK EDITIONS", "PROROK") {}
}