// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rebellion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    BOTTO - FOURTH PERIOD - REBELLION    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract REBEL is ERC721Creator {
    constructor() ERC721Creator("Rebellion", "REBEL") {}
}