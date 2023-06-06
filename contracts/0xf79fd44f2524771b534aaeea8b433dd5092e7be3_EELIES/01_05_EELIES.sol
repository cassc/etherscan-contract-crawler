// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eelies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//      zw      //
//    eelies    //
//              //
//              //
//////////////////


contract EELIES is ERC721Creator {
    constructor() ERC721Creator("Eelies", "EELIES") {}
}