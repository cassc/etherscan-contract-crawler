// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NeoNoir Cycle
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//              ___       .            .         //
//    .-..-,.-.     .-..-...-.  .-. ..-| .-,     //
//    ' '`'-`-'     ' '`-'''    `-'-|`-'-`'-     //
//                            .   `-'    .       //
//    .-,.-.-..-..-..-,.-.-  -|-.-..-. .-|-.     //
//    `'-' ' '|-''  `'--'-'   '-'  `-`--'' '-    //
//            '                                  //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract NNCET is ERC721Creator {
    constructor() ERC721Creator("NeoNoir Cycle", "NNCET") {}
}