// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Insascribbles
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Insascribbles    //
//                     //
//                     //
/////////////////////////


contract INSA is ERC721Creator {
    constructor() ERC721Creator("Insascribbles", "INSA") {}
}