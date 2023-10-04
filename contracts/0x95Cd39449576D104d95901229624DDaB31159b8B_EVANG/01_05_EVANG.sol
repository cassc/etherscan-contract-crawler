// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evangelia by Walter Padao
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//       ,ggggggg,                                                                                                                  ,ggg,      gg      ,gg                                             ,ggggggggggg,                                                //
//     ,dP""""""Y8b                                                            ,dPYb,                        ,dPYb,                dP""Y8a     88     ,8P           ,dPYb,   I8                       dP"""88""""""Y8,              8I                              //
//     d8'    a  Y8                                                            IP'`Yb                        IP'`Yb                Yb, `88     88     d8'           IP'`Yb   I8                       Yb,  88      `8b              8I                              //
//     88     "Y8P'                                                            I8  8I  gg                    I8  8I                 `"  88     88     88            I8  8I88888888                     `"  88      ,8P              8I                              //
//     `8baaaa                                                                 I8  8'  ""                    I8  8'                     88     88     88            I8  8'   I8                            88aaaad8P"               8I                              //
//    ,d8P""""        ggg    gg   ,gggg,gg   ,ggg,,ggg,     ,gggg,gg   ,ggg,   I8 dP   gg     ,gggg,gg       I8 dP      gg     gg       88     88     88  ,gggg,gg  I8 dP    I8    ,ggg,    ,gggggg,       88""""",gggg,gg    ,gggg,8I    ,gggg,gg    ,ggggg,       //
//    d8"            d8"Yb   88bgdP"  "Y8I  ,8" "8P" "8,   dP"  "Y8I  i8" "8i  I8dP    88    dP"  "Y8I       I8dP   88ggI8     8I       88     88     88 dP"  "Y8I  I8dP     I8   i8" "8i   dP""""8I       88    dP"  "Y8I   dP"  "Y8I   dP"  "Y8I   dP"  "Y8ggg    //
//    Y8,           dP  I8   8I i8'    ,8I  I8   8I   8I  i8'    ,8I  I8, ,8I  I8P     88   i8'    ,8I       I8P    8I  I8,   ,8I       Y8    ,88,    8Pi8'    ,8I  I8P     ,I8,  I8, ,8I  ,8'    8I       88   i8'    ,8I  i8'    ,8I  i8'    ,8I  i8'    ,8I      //
//    `Yba,,_____,,dP   I8, ,8I,d8,   ,d8b,,dP   8I   Yb,,d8,   ,d8I  `YbadP' ,d8b,_ _,88,_,d8,   ,d8b,     ,d8b,  ,8I ,d8b, ,d8I        Yb,,d8""8b,,dP,d8,   ,d8b,,d8b,_  ,d88b, `YbadP' ,dP     Y8,      88  ,d8,   ,d8b,,d8,   ,d8b,,d8,   ,d8b,,d8,   ,d8'      //
//      `"Y88888888"     "Y8P" P"Y8888P"`Y88P'   8I   `Y8P"Y8888P"888888P"Y8888P'"Y888P""Y8P"Y8888P"`Y8     8P'"Y88P"' P""Y88P"888        "88"    "88" P"Y8888P"`Y88P'"Y88 8P""Y8888P"Y8888P      `Y8      88  P"Y8888P"`Y8P"Y8888P"`Y8P"Y8888P"`Y8P"Y8888P"        //
//                                                              ,d8I'                                                    ,d8I'                                                                                                                                      //
//                                                            ,dP'8I                                                   ,dP'8I                                                                                                                                       //
//                                                           ,8"  8I                                                  ,8"  8I                                                                                                                                       //
//                                                           I8   8I                                                  I8   8I                                                                                                                                       //
//                                                           `8, ,8I                                                  `8, ,8I                                                                                                                                       //
//                                                            `Y8P"                                                    `Y8P"                                                                                                                                        //
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EVANG is ERC721Creator {
    constructor() ERC721Creator("Evangelia by Walter Padao", "EVANG") {}
}