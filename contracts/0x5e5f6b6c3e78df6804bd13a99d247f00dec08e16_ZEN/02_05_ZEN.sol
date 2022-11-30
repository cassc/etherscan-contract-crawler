// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Moment of Zen by Godwits
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//             88                                                                               //
//      ,d     88                                                                               //
//      88     88                                                                               //
//    MM88MMM  88,dPPYba,    ,adPPYba,                                                          //
//      88     88P'    "8a  a8P_____88                                                          //
//      88     88       88  8PP"""""""                                                          //
//      88,    88       88  "8b,   ,aa                                                          //
//      "Y888  88       88   `"Ybbd8"'                                                          //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                   ,d         //
//                                                                                   88         //
//    88,dPYba,,adPYba,    ,adPPYba,   88,dPYba,,adPYba,    ,adPPYba,  8b,dPPYba,  MM88MMM      //
//    88P'   "88"    "8a  a8"     "8a  88P'   "88"    "8a  a8P_____88  88P'   `"8a   88         //
//    88      88      88  8b       d8  88      88      88  8PP"""""""  88       88   88         //
//    88      88      88  "8a,   ,a8"  88      88      88  "8b,   ,aa  88       88   88,        //
//    88      88      88   `"YbbdP"'   88      88      88   `"Ybbd8"'  88       88   "Y888      //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                   ad88                                                                       //
//                  d8"                                                                         //
//                  88                                                                          //
//     ,adPPYba,  MM88MMM                                                                       //
//    a8"     "8a   88                                                                          //
//    8b       d8   88                                                                          //
//    "8a,   ,a8"   88                                                                          //
//     `"YbbdP"'    88                                                                          //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//    888888888   ,adPPYba,  8b,dPPYba,                                                         //
//         a8P"  a8P_____88  88P'   `"8a                                                        //
//      ,d8P'    8PP"""""""  88       88                                                        //
//    ,d8"       "8b,   ,aa  88       88                                                        //
//    888888888   `"Ybbd8"'  88       88                                                        //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//    88                                                                                        //
//    88                                                                                        //
//    88                                                                                        //
//    88,dPPYba,   8b       d8                                                                  //
//    88P'    "8a  `8b     d8'                                                                  //
//    88       d8   `8b   d8'                                                                   //
//    88b,   ,a8"    `8b,d8'                                                                    //
//    8Y"Ybbd8"'       Y88'                                                                     //
//                     d8'                                                                      //
//                    d8'                                                                       //
//                                                                                              //
//                                       88                      88                             //
//                                       88                      ""    ,d                       //
//                                       88                            88                       //
//     ,adPPYb,d8   ,adPPYba,    ,adPPYb,88  8b      db      d8  88  MM88MMM  ,adPPYba,         //
//    a8"    `Y88  a8"     "8a  a8"    `Y88  `8b    d88b    d8'  88    88     I8[    ""         //
//    8b       88  8b       d8  8b       88   `8b  d8'`8b  d8'   88    88      `"Y8ba,          //
//    "8a,   ,d88  "8a,   ,a8"  "8a,   ,d88    `8bd8'  `8bd8'    88    88,    aa    ]8I         //
//     `"YbbdP"Y8   `"YbbdP"'    `"8bbdP"Y8      YP      YP      88    "Y888  `"YbbdP"'         //
//     aa,    ,88                                                                               //
//      "Y8bbdP"                                                                                //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract ZEN is ERC721Creator {
    constructor() ERC721Creator("The Moment of Zen by Godwits", "ZEN") {}
}