// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Disorder
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//             8I                                                  8I                         //
//             8I                                                  8I                         //
//             8I   gg                                             8I                         //
//             8I   ""                                             8I                         //
//       ,gggg,8I   gg     ,g,       ,ggggg,     ,gggggg,    ,gggg,8I   ,ggg,    ,gggggg,     //
//      dP"  "Y8I   88    ,8'8,     dP"  "Y8ggg  dP""""8I   dP"  "Y8I  i8" "8i   dP""""8I     //
//     i8'    ,8I   88   ,8'  Yb   i8'    ,8I   ,8'    8I  i8'    ,8I  I8, ,8I  ,8'    8I     //
//    ,d8,   ,d8b,_,88,_,8'_   8) ,d8,   ,d8'  ,dP     Y8,,d8,   ,d8b, `YbadP' ,dP     Y8,    //
//    P"Y8888P"`Y88P""Y8P' "YY8P8PP"Y8888P"    8P      `Y8P"Y8888P"`Y8888P"Y8888P      `Y8    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract dis is ERC1155Creator {
    constructor() ERC1155Creator("Disorder", "dis") {}
}