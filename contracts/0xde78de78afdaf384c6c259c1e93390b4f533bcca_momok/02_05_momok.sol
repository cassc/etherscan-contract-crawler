// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: momok
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    • ▌ ▄ ·.       • ▌ ▄ ·.       ▄ •▄     //
//    ·██ ▐███▪▪     ·██ ▐███▪▪     █▌▄▌▪    //
//    ▐█ ▌▐▌▐█· ▄█▀▄ ▐█ ▌▐▌▐█· ▄█▀▄ ▐▀▀▄·    //
//    ██ ██▌▐█▌▐█▌.▐▌██ ██▌▐█▌▐█▌.▐▌▐█.█▌    //
//    ▀▀  █▪▀▀▀ ▀█▄▀▪▀▀  █▪▀▀▀ ▀█▄▀▪·▀  ▀    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract momok is ERC1155Creator {
    constructor() ERC1155Creator("momok", "momok") {}
}