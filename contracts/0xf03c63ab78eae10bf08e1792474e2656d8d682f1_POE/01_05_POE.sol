// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nuova carta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    SE FOSSI VERSO    //
//                      //
//                      //
//////////////////////////


contract POE is ERC721Creator {
    constructor() ERC721Creator("Nuova carta", "POE") {}
}