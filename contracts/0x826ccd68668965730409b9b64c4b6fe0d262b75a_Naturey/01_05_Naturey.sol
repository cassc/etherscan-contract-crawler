// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Naturey
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//     ,ggg, ,ggggggg,                                                                     //
//    dP""Y8,8P"""""Y8b                I8                                                  //
//    Yb, `8dP'     `88                I8                                                  //
//     `"  88'       88             88888888                                               //
//         88        88                I8                                                  //
//         88        88    ,gggg,gg    I8    gg      gg   ,gggggg,   ,ggg,   gg     gg     //
//         88        88   dP"  "Y8I    I8    I8      8I   dP""""8I  i8" "8i  I8     8I     //
//         88        88  i8'    ,8I   ,I8,   I8,    ,8I  ,8'    8I  I8, ,8I  I8,   ,8I     //
//         88        Y8,,d8,   ,d8b, ,d88b, ,d8b,  ,d8b,,dP     Y8, `YbadP' ,d8b, ,d8I     //
//         88        `Y8P"Y8888P"`Y888P""Y888P'"Y88P"`Y88P      `Y8888P"Y888P""Y88P"888    //
//                                                                                ,d8I'    //
//                                                                              ,dP'8I     //
//                                                                             ,8"  8I     //
//                                                                             I8   8I     //
//                                                                             `8, ,8I     //
//                                                                              `Y8P"      //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract Naturey is ERC721Creator {
    constructor() ERC721Creator("Naturey", "Naturey") {}
}