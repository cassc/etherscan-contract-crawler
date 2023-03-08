// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doooge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    Doooge    //
//              //
//              //
//////////////////


contract Doooge is ERC721Creator {
    constructor() ERC721Creator("Doooge", "Doooge") {}
}