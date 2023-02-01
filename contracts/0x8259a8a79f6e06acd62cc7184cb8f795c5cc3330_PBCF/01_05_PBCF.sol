// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paintings by cfart.eth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//     ,ggggggggggg,                                                                                                                                                                                                   //
//    dP"""88""""""Y8,                               I8                                                  ,dPYb,                               ,dPYb,                          I8                   I8    ,dPYb,        //
//    Yb,  88      `8b                               I8                                                  IP'`Yb                               IP'`Yb                          I8                   I8    IP'`Yb        //
//     `"  88      ,8P          gg                88888888  gg                                           I8  8I                               I8  8I                       88888888             88888888 I8  8I        //
//         88aaaad8P"           ""                   I8     ""                                           I8  8'                               I8  8'                          I8                   I8    I8  8'        //
//         88"""""   ,gggg,gg   gg    ,ggg,,ggg,     I8     gg    ,ggg,,ggg,     ,gggg,gg    ,g,         I8 dP       gg     gg        ,gggg,  I8 dP     ,gggg,gg  ,gggggg,    I8          ,ggg,    I8    I8 dPgg,      //
//         88       dP"  "Y8I   88   ,8" "8P" "8,    I8     88   ,8" "8P" "8,   dP"  "Y8I   ,8'8,        I8dP   88gg I8     8I       dP"  "Yb I8dP     dP"  "Y8I  dP""""8I    I8         i8" "8i   I8    I8dP" "8I     //
//         88      i8'    ,8I   88   I8   8I   8I   ,I8,    88   I8   8I   8I  i8'    ,8I  ,8'  Yb       I8P    8I   I8,   ,8I      i8'       I8P     i8'    ,8I ,8'    8I   ,I8,        I8, ,8I  ,I8,   I8P    I8     //
//         88     ,d8,   ,d8b,_,88,_,dP   8I   Yb, ,d88b, _,88,_,dP   8I   Yb,,d8,   ,d8I ,8'_   8)     ,d8b,  ,8I  ,d8b, ,d8I     ,d8,_    _,d8b,_  ,d8,   ,d8b,dP     Y8, ,d88b,  d8b  `YbadP' ,d88b, ,d8     I8,    //
//         88     P"Y8888P"`Y88P""Y88P'   8I   `Y888P""Y888P""Y88P'   8I   `Y8P"Y8888P"888P' "YY8P8P    8P'"Y88P"'  P""Y88P"888    P""Y8888PPPI8"8888P"Y8888P"`Y8P      `Y888P""Y88 Y8P 888P"Y8888P""Y8888P     `Y8    //
//                                                                                   ,d8I'                                ,d8I'               I8 `8,                                                                   //
//                                                                                 ,dP'8I                               ,dP'8I                I8  `8,                                                                  //
//                                                                                ,8"  8I                              ,8"  8I                I8   8I                                                                  //
//                                                                                I8   8I                              I8   8I                I8   8I                                                                  //
//                                                                                `8, ,8I                              `8, ,8I                I8, ,8'                                                                  //
//                                                                                 `Y8P"                                `Y8P"                  "Y8P'                                                                   //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PBCF is ERC721Creator {
    constructor() ERC721Creator("Paintings by cfart.eth", "PBCF") {}
}