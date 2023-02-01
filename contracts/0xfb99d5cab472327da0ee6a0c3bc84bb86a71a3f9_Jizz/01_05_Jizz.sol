// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuperNesGraphics
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//    ▄▄▄   ▄▄▄·  ▐ ▄ ·▄▄▄▄        • ▌ ▄ ·.     //
//    ▀▄ █·▐█ ▀█ •█▌▐███▪ ██ ▪     ·██ ▐███▪    //
//    ▐▀▀▄ ▄█▀▀█ ▐█▐▐▌▐█· ▐█▌ ▄█▀▄ ▐█ ▌▐▌▐█·    //
//    ▐█•█▌▐█ ▪▐▌██▐█▌██. ██ ▐█▌.▐▌██ ██▌▐█▌    //
//    .▀  ▀ ▀  ▀ ▀▀ █▪▀▀▀▀▀•  ▀█▄▀▪▀▀  █▪▀▀▀    //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Jizz is ERC1155Creator {
    constructor() ERC1155Creator("SuperNesGraphics", "Jizz") {}
}