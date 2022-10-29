// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ThatWeirdNft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//      _____                _   _         //
//     |_ " _| __        __ | \ |"|        //
//       | |   \"\      /"/<|  \| |>       //
//      /| |\  /\ \ /\ / /\U| |\  |u       //
//     u |_|U U  \ V  V /  U|_| \_|        //
//     _// \\_.-,_\ /\ /_,-.||   \\,-.     //
//    (__) (__)\_)-'  '-(_/ (_")  (_/      //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TWN is ERC721Creator {
    constructor() ERC721Creator("ThatWeirdNft", "TWN") {}
}