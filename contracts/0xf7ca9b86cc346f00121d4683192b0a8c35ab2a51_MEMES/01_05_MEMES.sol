// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maxwell Memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//     ,ggg, ,ggg,_,ggg,                                                                              //
//    dP""Y8dP""Y88P""Y8b                                                      ,dPYb, ,dPYb,          //
//    Yb, `88'  `88'  `88                                                      IP'`Yb IP'`Yb          //
//     `"  88    88    88                                                      I8  8I I8  8I          //
//         88    88    88                                                      I8  8' I8  8'          //
//         88    88    88    ,gggg,gg     ,gg,   ,gg gg    gg    gg    ,ggg,   I8 dP  I8 dP           //
//         88    88    88   dP"  "Y8I    d8""8b,dP"  I8    I8    88bg i8" "8i  I8dP   I8dP            //
//         88    88    88  i8'    ,8I   dP   ,88"    I8    I8    8I   I8, ,8I  I8P    I8P             //
//         88    88    Y8,,d8,   ,d8b,,dP  ,dP"Y8,  ,d8,  ,d8,  ,8I   `YbadP' ,d8b,_ ,d8b,_           //
//         88    88    `Y8P"Y8888P"`Y88"  dP"   "Y88P""Y88P""Y88P"   888P"Y8888P'"Y888P'"Y88          //
//                                                                                                    //
//                                                                                                    //
//                                       H E A V Y A L I E N                                          //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEMES is ERC1155Creator {
    constructor() ERC1155Creator("Maxwell Memes", "MEMES") {}
}