// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HairFruitSeries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     ,ggg,        gg  ,gggggggggggggg    ,gg,       //
//    dP""Y8b       88 dP""""""88""""""   i8""8i      //
//    Yb, `88       88 Yb,_    88         `8,,8'      //
//     `"  88       88  `""    88          `88'       //
//         88aaaaaaa88      ggg88gggg      dP"8,      //
//         88"""""""88         88   8     dP' `8a     //
//         88       88         88        dP'   `Yb    //
//         88       88   gg,   88    _ ,dP'     I8    //
//         88       Y8,   "Yb,,8P    "888,,____,dP    //
//         88       `Y8     "Y8P'    a8P"Y88888P"     //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract HFS is ERC721Creator {
    constructor() ERC721Creator("HairFruitSeries", "HFS") {}
}