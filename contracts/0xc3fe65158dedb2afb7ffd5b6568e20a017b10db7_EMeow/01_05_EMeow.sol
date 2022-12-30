// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eli & Mateo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//          |\      _,,,---,,_                    |\__/,|   (`\     //
//    ZZZzz /,`.-'`'    -.  ;-;;,_              _.|o o  |_   ) )    //
//         |,4-  ) )-,_. ,\ (  `'-'           -(((---(((--------    //
//        '---''(_/--'  `-'\_)                                      //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract EMeow is ERC721Creator {
    constructor() ERC721Creator("Eli & Mateo", "EMeow") {}
}