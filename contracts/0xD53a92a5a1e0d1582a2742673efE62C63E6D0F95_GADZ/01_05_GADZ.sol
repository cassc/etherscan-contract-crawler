// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GadzArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//            GGGGGGGGGGGGG               AAA               DDDDDDDDDDDDD       ZZZZZZZZZZZZZZZZZZZ    //
//         GGG::::::::::::G              A:::A              D::::::::::::DDD    Z:::::::::::::::::Z    //
//       GG:::::::::::::::G             A:::::A             D:::::::::::::::DD  Z:::::::::::::::::Z    //
//      G:::::GGGGGGGG::::G            A:::::::A            DDD:::::DDDDD:::::D Z:::ZZZZZZZZ:::::Z     //
//     G:::::G       GGGGGG           A:::::::::A             D:::::D    D:::::DZZZZZ     Z:::::Z      //
//    G:::::G                        A:::::A:::::A            D:::::D     D:::::D       Z:::::Z        //
//    G:::::G                       A:::::A A:::::A           D:::::D     D:::::D      Z:::::Z         //
//    G:::::G    GGGGGGGGGG        A:::::A   A:::::A          D:::::D     D:::::D     Z:::::Z          //
//    G:::::G    G::::::::G       A:::::A     A:::::A         D:::::D     D:::::D    Z:::::Z           //
//    G:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A        D:::::D     D:::::D   Z:::::Z            //
//    G:::::G        G::::G     A:::::::::::::::::::::A       D:::::D     D:::::D  Z:::::Z             //
//     G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A      D:::::D    D:::::DZZZ:::::Z     ZZZZZ    //
//      G:::::GGGGGGGG::::G   A:::::A             A:::::A   DDD:::::DDDDD:::::D Z::::::ZZZZZZZZ:::Z    //
//       GG:::::::::::::::G  A:::::A               A:::::A  D:::::::::::::::DD  Z:::::::::::::::::Z    //
//         GGG::::::GGG:::G A:::::A                 A:::::A D::::::::::::DDD    Z:::::::::::::::::Z    //
//            GGGGGG   GGGGAAAAAAA                   AAAAAAADDDDDDDDDDDDD       ZZZZZZZZZZZZZZZZZZZ    //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GADZ is ERC1155Creator {
    constructor() ERC1155Creator("GadzArt", "GADZ") {}
}