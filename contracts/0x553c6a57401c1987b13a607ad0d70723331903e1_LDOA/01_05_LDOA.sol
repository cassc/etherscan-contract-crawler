// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lucid Dreaming Of Atlantis.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    !                                                  //
//    !                                                  //
//    !     ╦  ╦ ╦╔═╗╦╔╦╗  ╔╦╗╦═╗╔═╗╔═╗╔╦╗╦╔╗╔╔═╗        //
//    !     ║  ║ ║║  ║ ║║   ║║╠╦╝║╣ ╠═╣║║║║║║║║ ╦        //
//    !     ╩═╝╚═╝╚═╝╩═╩╝  ═╩╝╩╚═╚═╝╩ ╩╩ ╩╩╝╚╝╚═╝        //
//    !     ╔═╗╔═╗  ╔═╗╔╦╗╦  ╔═╗╔╗╔╔╦╗╦╔═╗               //
//    !     ║ ║╠╣   ╠═╣ ║ ║  ╠═╣║║║ ║ ║╚═╗               //
//    !     ╚═╝╚    ╩ ╩ ╩ ╩═╝╩ ╩╝╚╝ ╩ ╩╚═╝               //
//    !                                                  //
//    !                                                  //
//    !     An NFT project from VisionArt.AI             //
//    !                                                  //
//    !                                                  //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract LDOA is ERC721Creator {
    constructor() ERC721Creator("Lucid Dreaming Of Atlantis.", "LDOA") {}
}