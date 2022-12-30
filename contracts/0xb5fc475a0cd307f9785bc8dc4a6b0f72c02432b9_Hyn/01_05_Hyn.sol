// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hyeonos
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    Gm    //
//          //
//          //
//////////////


contract Hyn is ERC721Creator {
    constructor() ERC721Creator("Hyeonos", "Hyn") {}
}