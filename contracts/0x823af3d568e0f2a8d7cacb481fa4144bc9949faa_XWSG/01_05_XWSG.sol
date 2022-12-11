// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XWAVE Sigillaria
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//     .oooooo..o  o8o              o8o  oooo  oooo                      o8o                //
//    d8P'    `Y8  `"'              `"'  `888  `888                      `"'                //
//    Y88bo.      oooo   .oooooooo oooo   888   888   .oooo.   oooo d8b oooo   .oooo.       //
//     `"Y8888o.  `888  888' `88b  `888   888   888  `P  )88b  `888""8P `888  `P  )88b      //
//         `"Y88b  888  888   888   888   888   888   .oP"888   888      888   .oP"888      //
//    oo     .d8P  888  `88bod8P'   888   888   888  d8(  888   888      888  d8(  888      //
//    8""88888P'  o888o `8oooooo.  o888o o888o o888o `Y888""8o d888b    o888o `Y888""8o     //
//                      d"     YD                                                           //
//                      "Y88888P'                                                           //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract XWSG is ERC721Creator {
    constructor() ERC721Creator("XWAVE Sigillaria", "XWSG") {}
}