// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: haruyu Souvenirs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                        ■     //
//                      ■                ■ ■    //
//      ■■■■         ■   ■       ■     ■■       //
//         ■         ■   ■■■■    ■      ■       //
//         ■  ■      ■■■■   ■■   ■  ■■■■■■      //
//        ■■  ■    ■■■■      ■   ■      ■       //
//     ■■■■■■■■       ■■    ■    ■      ■       //
//    ■■ ■■   ■■■      ■ ■■■     ■■    ■■       //
//    ■  ■   ■■ ■      ■         ■■    ■        //
//    ■ ■■   ■         ■■        ■■    ■        //
//     ■■   ■           ■        ■    ■         //
//                      ■            ■          //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract OMIYAGE is ERC1155Creator {
    constructor() ERC1155Creator("haruyu Souvenirs", "OMIYAGE") {}
}