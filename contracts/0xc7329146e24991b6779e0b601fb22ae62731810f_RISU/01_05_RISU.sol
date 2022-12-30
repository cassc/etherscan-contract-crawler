// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art by Risu
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                    d8b                               d8,                     //
//                          d8P       ?88                              `8P                      //
//                       d888888P      88b                                                      //
//     d888b8b    88bd88b  ?88'        888888b ?88   d8P       88bd88b  88b .d888b,?88   d8P    //
//    d8P' ?88    88P'  `  88P         88P `?8bd88   88        88P'  `  88P ?8b,   d88   88     //
//    88b  ,88b  d88       88b        d88,  d88?8(  d88       d88      d88    `?8b ?8(  d88     //
//    `?88P'`88bd88'       `?8b      d88'`?88P'`?88P'?8b     d88'     d88' `?888P' `?88P'?8b    //
//                                                    )88                                       //
//                                                   ,d8P                                       //
//                                                `?888P'                                       //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract RISU is ERC721Creator {
    constructor() ERC721Creator("Art by Risu", "RISU") {}
}