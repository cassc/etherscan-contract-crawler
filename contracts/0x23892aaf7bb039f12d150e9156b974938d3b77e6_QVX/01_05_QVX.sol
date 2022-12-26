// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: qvxdri
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//                                                   8I                      //
//                                                   8I                      //
//                                                   8I              gg      //
//                                                   8I              ""      //
//       ,gggg,gg     ggg    gg    ,gg,   ,gg  ,gggg,8I   ,gggggg,   gg      //
//      dP"  "Y8I    d8"Yb   88bg d8""8b,dP"  dP"  "Y8I   dP""""8I   88      //
//     i8'    ,8I   dP  I8   8I  dP   ,88"   i8'    ,8I  ,8'    8I   88      //
//    ,d8,   ,d8b ,dP   I8, ,8I,dP  ,dP"Y8, ,d8,   ,d8b,,dP     Y8,_,88,_    //
//    P"Y8888P"88d8"     "Y8P" 8"  dP"   "Y8P"Y8888P"`Y88P      `Y88P""Y8    //
//             I8P                                                           //
//             I8'                                                           //
//             I8                                                            //
//             I8                                                            //
//             I8                                                            //
//             I8                                                            //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract QVX is ERC721Creator {
    constructor() ERC721Creator("qvxdri", "QVX") {}
}