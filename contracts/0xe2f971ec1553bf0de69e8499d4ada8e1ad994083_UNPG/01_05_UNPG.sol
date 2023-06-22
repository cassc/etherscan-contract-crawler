// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unplugged
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//     ,ggg,         gg                                                                                                                                                         //
//    dP""Y8a        88                            ,dPYb,                                                      8I                                                               //
//    Yb, `88        88                            IP'`Yb                                                      8I                                                               //
//     `"  88        88                            I8  8I                                                      8I                                                               //
//         88        88                            I8  8'                                                      8I                                                               //
//         88        88   ,ggg,,ggg,   gg,gggg,    I8 dP  gg      gg    ,gggg,gg    ,gggg,gg   ,ggg,     ,gggg,8I                                                               //
//         88        88  ,8" "8P" "8,  I8P"  "Yb   I8dP   I8      8I   dP"  "Y8I   dP"  "Y8I  i8" "8i   dP"  "Y8I                                                               //
//         88        88  I8   8I   8I  I8'    ,8i  I8P    I8,    ,8I  i8'    ,8I  i8'    ,8I  I8, ,8I  i8'    ,8I                                                               //
//         Y8b,____,d88,,dP   8I   Yb,,I8 _  ,d8' ,d8b,_ ,d8b,  ,d8b,,d8,   ,d8I ,d8,   ,d8I  `YbadP' ,d8,   ,d8b,                                                              //
//          "Y888888P"Y88P'   8I   `Y8PI8 YY88888P8P'"Y888P'"Y88P"`Y8P"Y8888P"888P"Y8888P"888888P"Y888P"Y8888P"`Y8                                                              //
//                                     I8                                   ,d8I'       ,d8I'                                                                                   //
//                                     I8                                 ,dP'8I      ,dP'8I                                                                                    //
//                                     I8                                ,8"  8I     ,8"  8I                                                                                    //
//                                     I8                                I8   8I     I8   8I                                                                                    //
//                                     I8                                `8, ,8I     `8, ,8I                                                                                    //
//                                     I8                                 `Y8P"       `Y8P"                                                                                     //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//    Unplugged was born when my works disconnected from the digital and were born as physical works following my signature style, which is what is known as 'art informel'.    //
//    The collector will receive the physical work.                                                                                                                             //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UNPG is ERC721Creator {
    constructor() ERC721Creator("Unplugged", "UNPG") {}
}