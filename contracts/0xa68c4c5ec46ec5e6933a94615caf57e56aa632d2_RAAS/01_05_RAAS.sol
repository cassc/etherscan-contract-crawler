// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raging Abyss
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                              //
//                                                                                                                                              //
//     ,ggggggggggg,                                                                       ,ggg,                                                //
//    dP"""88""""""Y8,                                                                    dP""8I   ,dPYb,                                       //
//    Yb,  88      `8b                                                                   dP   88   IP'`Yb                                       //
//     `"  88      ,8P                           gg                                     dP    88   I8  8I                                       //
//         88aaaad8P"                            ""                                    ,8'    88   I8  8'                                       //
//         88""""Yb,      ,gggg,gg    ,gggg,gg   gg    ,ggg,,ggg,     ,gggg,gg         d88888888   I8 dP      gg     gg    ,g,       ,g,        //
//         88     "8b    dP"  "Y8I   dP"  "Y8I   88   ,8" "8P" "8,   dP"  "Y8I   __   ,8"     88   I8dP   88ggI8     8I   ,8'8,     ,8'8,       //
//         88      `8i  i8'    ,8I  i8'    ,8I   88   I8   8I   8I  i8'    ,8I  dP"  ,8P      Y8   I8P    8I  I8,   ,8I  ,8'  Yb   ,8'  Yb      //
//         88       Yb,,d8,   ,d8b,,d8,   ,d8I _,88,_,dP   8I   Yb,,d8,   ,d8I  Yb,_,dP       `8b,,d8b,  ,8I ,d8b, ,d8I ,8'_   8) ,8'_   8)     //
//         88        Y8P"Y8888P"`Y8P"Y8888P"8888P""Y88P'   8I   `Y8P"Y8888P"888  "Y8P"         `Y88P'"Y88P"' P""Y88P"888P' "YY8P8PP' "YY8P8P    //
//                                        ,d8I'                           ,d8I'                                    ,d8I'                        //
//                                      ,dP'8I                          ,dP'8I                                   ,dP'8I                         //
//                                     ,8"  8I                         ,8"  8I                                  ,8"  8I                         //
//                                     I8   8I                         I8   8I                                  I8   8I                         //
//                                     `8, ,8I                         `8, ,8I                                  `8, ,8I                         //
//                                      `Y8P"                           `Y8P"                                    `Y8P"                          //
//                                                                                                                                              //
//                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RAAS is ERC721Creator {
    constructor() ERC721Creator("Raging Abyss", "RAAS") {}
}