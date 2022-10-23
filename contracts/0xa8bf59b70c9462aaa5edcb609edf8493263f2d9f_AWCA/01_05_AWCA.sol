// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Consistent Appearance
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//               ,ggg,                                                                               //
//              dP""8I   ,dPYb,                                                                      //
//             dP   88   IP'`Yb                                                                      //
//            dP    88   I8  8I  gg                                                                  //
//           ,8'    88   I8  8'  ""                                                                  //
//           d88888888   I8 dP   gg     ,gggg,   ,ggg,                                               //
//     __   ,8"     88   I8dP    88    dP"  "Yb i8" "8i                                              //
//    dP"  ,8P      Y8   I8P     88   i8'       I8, ,8I                                              //
//    Yb,_,dP       `8b,,d8b,_ _,88,_,d8,_    _ `YbadP'                                              //
//     "Y8P"         `Y88P'"Y888P""Y8P""Y8888PP888P"Y888                                             //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
//     ,ggg,      gg      ,gg                                                                        //
//    dP""Y8a     88     ,8P                                    8I                                   //
//    Yb, `88     88     d8'                                    8I                                   //
//     `"  88     88     88                                     8I                                   //
//         88     88     88                                     8I                                   //
//         88     88     88    ,ggggg,     ,ggg,,ggg,     ,gggg,8I   ,ggg,    ,gggggg,    ,g,        //
//         88     88     88   dP"  "Y8ggg ,8" "8P" "8,   dP"  "Y8I  i8" "8i   dP""""8I   ,8'8,       //
//         Y8    ,88,    8P  i8'    ,8I   I8   8I   8I  i8'    ,8I  I8, ,8I  ,8'    8I  ,8'  Yb      //
//          Yb,,d8""8b,,dP  ,d8,   ,d8'  ,dP   8I   Yb,,d8,   ,d8b, `YbadP' ,dP     Y8,,8'_   8)     //
//           "88"    "88"   P"Y8888P"    8P'   8I   `Y8P"Y8888P"`Y8888P"Y8888P      `Y8P' "YY8P8P    //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract AWCA is ERC721Creator {
    constructor() ERC721Creator("Consistent Appearance", "AWCA") {}
}