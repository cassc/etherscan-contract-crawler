// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solemn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Art by Solemn    //
//                     //
//                     //
/////////////////////////


contract Solemn is ERC721Creator {
    constructor() ERC721Creator("Solemn", "Solemn") {}
}