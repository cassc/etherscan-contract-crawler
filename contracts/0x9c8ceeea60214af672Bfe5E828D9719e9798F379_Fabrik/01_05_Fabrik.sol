// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FabrikRedeem
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//     ,gggggggggggggg                                                 //
//    dP""""""88""""""        ,dPYb,                     ,dPYb,        //
//    Yb,_    88              IP'`Yb                     IP'`Yb        //
//     `""    88              I8  8I                gg   I8  8I        //
//         ggg88gggg          I8  8'                ""   I8  8bgg,     //
//            88   8,gggg,gg  I8 dP      ,gggggg,   gg   I8 dP" "8     //
//            88   dP"  "Y8I  I8dP   88ggdP""""8I   88   I8d8bggP"     //
//      gg,   88  i8'    ,8I  I8P    8I ,8'    8I   88   I8P' "Yb,     //
//       "Yb,,8P ,d8,   ,d8b,,d8b,  ,8I,dP     Y8,_,88,_,d8    `Yb,    //
//         "Y8P' P"Y8888P"`Y88P'"Y88P"'8P      `Y88P""Y888P      Y8    //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract Fabrik is ERC721Creator {
    constructor() ERC721Creator("FabrikRedeem", "Fabrik") {}
}