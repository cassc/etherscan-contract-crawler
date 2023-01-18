// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Drop 666
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ¯\_(ツ)_/¯    //
//                 //
//                 //
/////////////////////


contract TD666 is ERC721Creator {
    constructor() ERC721Creator("Test Drop 666", "TD666") {}
}