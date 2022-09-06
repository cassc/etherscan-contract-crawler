// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     ,dPYb,  ,dPYb,                                  //
//     IP'`Yb  IP'`Yb                                  //
//     I8  8I  I8  8I                                  //
//     I8  8'  I8  8'                                  //
//     I8 dP   I8 dP    ,ggggg,    gg    gg    gg      //
//     I8dP    I8dP    dP"  "Y8ggg I8    I8    88bg    //
//     I8P     I8P    i8'    ,8I   I8    I8    8I      //
//    ,d8b,_  ,d8b,_ ,d8,   ,d8'  ,d8,  ,d8,  ,8I      //
//    PI8"888 8P'"Y88P"Y8888P"    P""Y88P""Y88P"       //
//     I8 `8,                                          //
//     I8  `8,                                         //
//     I8   8I                                         //
//     I8   8I                                         //
//     I8, ,8'                                         //
//      "Y8P'                                          //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract erdyflow is ERC721Creator {
    constructor() ERC721Creator("flow", "erdyflow") {}
}