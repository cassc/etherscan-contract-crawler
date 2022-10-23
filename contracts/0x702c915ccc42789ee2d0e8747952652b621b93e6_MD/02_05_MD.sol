// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MaloDraws
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    Documenting the journey. It all started with bitmonkey.tv    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract MD is ERC721Creator {
    constructor() ERC721Creator("MaloDraws", "MD") {}
}