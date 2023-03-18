// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apples & Oranges
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//          db      ,gM""bg      .g8""8q.       //
//         ;MM:     8MI  ,8    .dP'    `YM.     //
//        ,V^MM.     WMp,"     dM'      `MM     //
//       ,M  `MM    ,gPMN.  jM"MM        MM     //
//       AbmmmqMA  ,M.  YMp.M' MM.      ,MP     //
//      A'     VML 8Mp   ,MMp  `Mb.    ,dP'     //
//    .AMA.   .AMMA`YMbmm'``MMm. `"bmmd"'       //
//                       .                      //
//       `   __.  ,   .  |     ___  _  .-       //
//       | .'   \ |   |  |   .'   `  \,'        //
//       | |    | |   |  |   |----'  /\         //
//       /  `._.' `._/| /\__ `.___, /  \        //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract AO is ERC721Creator {
    constructor() ERC721Creator("Apples & Oranges", "AO") {}
}