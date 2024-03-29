// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SaraNmt Calendar
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//     ,ggg,        gg                                                  ,ggg, ,ggggggg,                              ,ggg,         gg                                     //
//    dP""Y8b       88                                                 dP""Y8,8P"""""Y8b                            dP""Y8a        88                                     //
//    Yb, `88       88                                                 Yb, `8dP'     `88                            Yb, `88        88                                     //
//     `"  88       88                                                  `"  88'       88                             `"  88        88                                     //
//         88aaaaaaa88                                                      88        88                                 88        88                                     //
//         88"""""""88    ,gggg,gg  gg,gggg,    gg,gggg,    gg     gg       88        88   ,ggg,   gg    gg    gg        88        88   ,ggg,     ,gggg,gg   ,gggggg,     //
//         88       88   dP"  "Y8I  I8P"  "Yb   I8P"  "Yb   I8     8I       88        88  i8" "8i  I8    I8    88bg      88       ,88  i8" "8i   dP"  "Y8I   dP""""8I     //
//         88       88  i8'    ,8I  I8'    ,8i  I8'    ,8i  I8,   ,8I       88        88  I8, ,8I  I8    I8    8I        Y8b,___,d888  I8, ,8I  i8'    ,8I  ,8'    8I     //
//         88       Y8,,d8,   ,d8b,,I8 _  ,d8' ,I8 _  ,d8' ,d8b, ,d8I       88        Y8, `YbadP' ,d8,  ,d8,  ,8I         "Y88888P"88, `YbadP' ,d8,   ,d8b,,dP     Y8,    //
//         88       `Y8P"Y8888P"`Y8PI8 YY88888PPI8 YY88888PP""Y88P"888      88        `Y8888P"Y888P""Y88P""Y88P"               ,ad8888888P"Y888P"Y8888P"`Y88P      `Y8    //
//                                  I8          I8               ,d8I'                                                        d8P" 88                                     //
//                                  I8          I8             ,dP'8I                                                       ,d8'   88                                     //
//                                  I8          I8            ,8"  8I                                                       d8'    88                                     //
//                                  I8          I8            I8   8I                                                       88     88                                     //
//                                  I8          I8            `8, ,8I                                                       Y8,_ _,88                                     //
//                                  I8          I8             `Y8P"                                                         "Y888P"                                      //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//      __                                                                                                                                                                //
//     (_   _. ._ _. |\ | ._ _ _|_                                                                                                                                        //
//     __) (_| | (_| | \| | | | |_                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CLNDR is ERC721Creator {
    constructor() ERC721Creator("SaraNmt Calendar", "CLNDR") {}
}