// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Endangered Species Project
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    🅣🅗🅔 ➎➎➒🅔🅡    //
//                      //
//                      //
//////////////////////////


contract ESPER is ERC721Creator {
    constructor() ERC721Creator("Endangered Species Project", "ESPER") {}
}