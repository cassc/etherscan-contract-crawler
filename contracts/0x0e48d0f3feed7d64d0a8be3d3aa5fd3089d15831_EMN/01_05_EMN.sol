// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eamons Photos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//      ,------.                          //
//       `-____-'        ,-----------.    //
//        ,i--i.         |Photography|    //
//       / @  @ \       /     By     |    //
//      | -.__.- | ___-' Eamon Bonner|    //
//       \.    ,/ """"""""""""""""""'     //
//       ,\""""/.                         //
//     ,'  `--'  `.                       //
//    (_,i'    `i._)                      //
//       |      |                         //
//       |  ,.  |                         //
//       | |  | |                         //
//       `-'  `-'                         //
//                                        //
//                                        //
////////////////////////////////////////////


contract EMN is ERC721Creator {
    constructor() ERC721Creator("Eamons Photos", "EMN") {}
}