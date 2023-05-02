// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTs ARE DUMB.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    ╔╗╔╔═╗╔╦╗┌─┐  ╔═╗╦═╗╔═╗  ╔╦╗╦ ╦╔╦╗╔╗       //
//    ║║║╠╣  ║ └─┐  ╠═╣╠╦╝║╣    ║║║ ║║║║╠╩╗      //
//    ╝╚╝╚   ╩ └─┘  ╩ ╩╩╚═╚═╝  ═╩╝╚═╝╩ ╩╚═╝ o    //
//    plEAsE G0 oUtSiDE, D0 DRuGs&HAvE sEx       //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract DUMB is ERC1155Creator {
    constructor() ERC1155Creator("NFTs ARE DUMB.", "DUMB") {}
}