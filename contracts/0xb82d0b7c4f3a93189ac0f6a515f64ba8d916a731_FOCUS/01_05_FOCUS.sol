// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Focus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    ┌─┐┌─┐┌─┐┬ ┬┌─┐    //
//    ├┤ │ ││  │ │└─┐    //
//    └  └─┘└─┘└─┘└─┘    //
//                       //
//                       //
///////////////////////////


contract FOCUS is ERC721Creator {
    constructor() ERC721Creator("Focus", "FOCUS") {}
}