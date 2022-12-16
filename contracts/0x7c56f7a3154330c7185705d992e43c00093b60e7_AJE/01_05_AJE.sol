// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Amaan Jahangir's Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    //////////////////////////    //
//    //                      //    //
//    //                      //    //
//    //      .`.   _ _       //    //
//    //    __;_ \ /,//`      //    //
//    //    --, `._) (  __    //    //
//    //     '//,,,  |_/(/    //    //
//    //          )_7"q`|>    //    //
//    //         /_|   >\     //    //
//    //                      //    //
//    //                      //    //
//    //////////////////////////    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract AJE is ERC1155Creator {
    constructor() ERC1155Creator("Amaan Jahangir's Editions", "AJE") {}
}