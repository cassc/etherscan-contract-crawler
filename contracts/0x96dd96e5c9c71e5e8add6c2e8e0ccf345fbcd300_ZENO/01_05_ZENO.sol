// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zeno's Republic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    !                                             o8o                                 //
//    !                                             `YP                                 //
//    !    oooooooo  .ooooo.  ooo. .oo.    .ooooo.   '   .oooo.o                        //
//    !   d'""7d8P  d88' `88b `888P"Y88b  d88' `88b     d88(  "8                        //
//    !     .d8P'   888ooo888  888   888  888   888     `"Y88b.                         //
//    !   .d8P'  .P 888    .o  888   888  888   888     o.  )88b                        //
//    !  d8888888P  `Y8bod8P' o888o o888o `Y8bod8P'     8""888P'                        //
//    !                                             .o8       oooo   o8o                //
//    !                                            "888       `888   `"'                //
//    !  oooo d8b  .ooooo.  oo.ooooo.  oooo  oooo   888oooo.   888  oooo   .ooooo.      //
//    !  `888""8P d88' `88b  888' `88b `888  `888   d88' `88b  888  `888  d88' `"Y8     //
//    !   888     888ooo888  888   888  888   888   888   888  888   888  888           //
//    !   888     888    .o  888   888  888   888   888   888  888   888  888   .o8     //
//    !  d888b    `Y8bod8P'  888bod8P'  `V88V"V8P'  `Y8bod8P' o888o o888o `Y8bod8P'     //
//    !                      888                                                        //
//    !                     o888o                                                       //
//    !                                                                                 //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract ZENO is ERC721Creator {
    constructor() ERC721Creator("Zeno's Republic", "ZENO") {}
}