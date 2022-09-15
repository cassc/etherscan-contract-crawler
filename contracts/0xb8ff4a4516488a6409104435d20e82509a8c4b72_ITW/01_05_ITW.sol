// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In That World
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    INTHATWORLDBYCRIZZ    //
//                          //
//                          //
//////////////////////////////


contract ITW is ERC721Creator {
    constructor() ERC721Creator("In That World", "ITW") {}
}