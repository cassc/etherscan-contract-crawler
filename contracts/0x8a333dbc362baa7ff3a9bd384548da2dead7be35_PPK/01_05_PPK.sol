// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE by KunTa
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    Pepe cultural memes                   //
//    Self-reflective digital paintings     //
//    New signature style                   //
//                                          //
//    Pepe KunTa                            //
//    Self-Taught Artist                    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract PPK is ERC721Creator {
    constructor() ERC721Creator("PEPE by KunTa", "PPK") {}
}