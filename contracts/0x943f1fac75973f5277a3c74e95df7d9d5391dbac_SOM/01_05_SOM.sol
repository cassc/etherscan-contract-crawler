// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: State of Mind
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    STATE OF MIND     //
//    25 EDITIONS       //
//                      //
//                      //
//////////////////////////


contract SOM is ERC721Creator {
    constructor() ERC721Creator("State of Mind", "SOM") {}
}