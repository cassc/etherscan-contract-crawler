// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAM WITH ME
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ╔╦╗╦═╗╔═╗╔═╗╔╦╗  ╦ ╦╦╔╦╗╦ ╦  ╔╦╗╔═╗    //
//     ║║╠╦╝║╣ ╠═╣║║║  ║║║║ ║ ╠═╣  ║║║║╣     //
//    ═╩╝╩╚═╚═╝╩ ╩╩ ╩  ╚╩╝╩ ╩ ╩ ╩  ╩ ╩╚═╝    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract DWM is ERC721Creator {
    constructor() ERC721Creator("DREAM WITH ME", "DWM") {}
}