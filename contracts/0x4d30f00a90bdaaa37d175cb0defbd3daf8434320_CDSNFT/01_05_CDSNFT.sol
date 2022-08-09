// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CoinDeskStudios
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//      .oooooo.              o8o              oooooooooo.                      oooo            //
//     d8P'  `Y8b             `"'              `888'   `Y8b                     `888            //
//    888           .ooooo.  oooo  ooo. .oo.    888      888  .ooooo.   .oooo.o  888  oooo      //
//    888          d88' `88b `888  `888P"Y88b   888      888 d88' `88b d88(  "8  888 .8P'       //
//    888          888   888  888   888   888   888      888 888ooo888 `"Y88b.   888888.        //
//    `88b    ooo  888   888  888   888   888   888     d88' 888    .o o.  )88b  888 `88b.      //
//     `Y8bood8P'  `Y8bod8P' o888o o888o o888o o888bood8P'   `Y8bod8P' 8""888P' o888o o888o     //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract CDSNFT is ERC721Creator {
    constructor() ERC721Creator("CoinDeskStudios", "CDSNFT") {}
}