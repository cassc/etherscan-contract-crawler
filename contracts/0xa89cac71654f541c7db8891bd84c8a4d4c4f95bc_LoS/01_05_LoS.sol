// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Layers of Self
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     © Roger Kilimanjaro - Layers of Self        //
//                                                 //
//    Original artwork: Self by Rik Oostenbroek    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract LoS is ERC721Creator {
    constructor() ERC721Creator("Layers of Self", "LoS") {}
}