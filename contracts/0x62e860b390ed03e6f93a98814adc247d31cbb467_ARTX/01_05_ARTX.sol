// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artemysia-X
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Storyteller     //
//    in              //
//    prose,          //
//    verse,          //
//    Ai,             //
//    manifestos,     //
//    nonfiction,     //
//    oil,            //
//    manga,          //
//    watercolor,     //
//    and             //
//    more.           //
//                    //
//                    //
////////////////////////


contract ARTX is ERC721Creator {
    constructor() ERC721Creator("Artemysia-X", "ARTX") {}
}