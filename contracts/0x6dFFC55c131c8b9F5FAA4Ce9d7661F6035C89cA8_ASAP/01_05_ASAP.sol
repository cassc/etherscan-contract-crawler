// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ASAP | KID LUV
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//          .o.        .oooooo..o       .o.       ooooooooo.                          //
//         .888.      d8P'    `Y8      .888.      `888   `Y88.                        //
//        .8"888.     Y88bo.          .8"888.      888   .d88'                        //
//       .8' `888.     `"Y8888o.     .8' `888.     888ooo88P'                         //
//      .88ooo8888.        `"Y88b   .88ooo8888.    888                                //
//     .8'     `888.  oo     .d8P  .8'     `888.   888                                //
//    o88o     o8888o 8""88888P'  o88o     o8888o o888o                               //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//    oooo    oooo ooooo oooooooooo.   ooooo        ooooo     ooo oooooo     oooo     //
//    `888   .8P'  `888' `888'   `Y8b  `888'        `888'     `8'  `888.     .8'      //
//     888  d8'     888   888      888  888          888       8    `888.   .8'       //
//     88888[       888   888      888  888          888       8     `888. .8'        //
//     888`88b.     888   888      888  888          888       8      `888.8'         //
//     888  `88b.   888   888     d88'  888       o  `88.    .8'       `888'          //
//    o888o  o888o o888o o888bood8P'   o888ooooood8    `YbodP'          `8'           //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract ASAP is ERC1155Creator {
    constructor() ERC1155Creator("ASAP | KID LUV", "ASAP") {}
}