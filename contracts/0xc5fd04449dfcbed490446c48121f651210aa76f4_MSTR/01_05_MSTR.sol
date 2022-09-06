// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mister Reborn
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Mister Reborn    //
//                     //
//                     //
/////////////////////////


contract MSTR is ERC721Creator {
    constructor() ERC721Creator("Mister Reborn", "MSTR") {}
}