// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Nouns Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                  *###               ###                  //
//                  *#####################                  //
//               &&&%#@@@@@   ###@@@@@   #&&&*              //
//               #####@@@@@   ###@@@@@   ####%              //
//                    ########   ########                   //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract ORDINALNOUNS is ERC1155Creator {
    constructor() ERC1155Creator("Ordinal Nouns Genesis", "ORDINALNOUNS") {}
}