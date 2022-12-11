// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Intend
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    ⚔️    //
//          //
//          //
//////////////


contract RWA is ERC721Creator {
    constructor() ERC721Creator("Intend", "RWA") {}
}