// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EMOCEAN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//       ,ggggggg, ,ggg, ,ggg,_,ggg,   _,gggggg,_        ,gggg,   ,ggggggg,          ,ggg,,ggg, ,ggggggg,      //
//     ,dP""""""Y8dP""Y8dP""Y88P""Y8b,d8P""d8P"Y8b,    ,88"""Y8b,dP""""""Y8b        dP""8dP""Y8,8P"""""Y8b     //
//     d8'    a  YYb, `88'  `88'  `8,d8'   Y8   "8b,dPd8"     `Yd8'    a  Y8       dP   8Yb, `8dP'     `88     //
//     88     "Y8P'`"  88    88    8d8'    `Ybaaad88Pd8'   8b  d88     "Y8P'      dP    88`"  88'       88     //
//     `8baaaa         88    88    88P       `""""Y8,8I    "Y88P`8baaaa          ,8'    88    88        88     //
//    ,d8P""""         88    88    88b            d8I8'        ,d8P""""          d88888888    88        88     //
//    d8"              88    88    8Y8,          ,8Pd8         d8"         __   ,8"     88    88        88     //
//    Y8,              88    88    8`Y8,        ,8P'Y8,        Y8,        dP"  ,8P      Y8    88        88     //
//    `Yba,,_____,     88    88    Y8`Y8b,,__,,d8P' `Yba,,_____`Yba,,_____Yb,_,dP       `8b,  88        Y8,    //
//      `"Y8888888     88    88    `Y8 `"Y8888P"'     `"Y8888888 `"Y8888888"Y8P"         `Y8  88        `Y8    //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EMOCEAN is ERC721Creator {
    constructor() ERC721Creator("EMOCEAN", "EMOCEAN") {}
}