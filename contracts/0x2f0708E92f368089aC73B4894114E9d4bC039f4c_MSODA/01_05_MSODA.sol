// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Michael Stone Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    █▓▒▒░░░Michael Stone Art░░░▒▒▓█    //
//                                       //
//                                       //
///////////////////////////////////////////


contract MSODA is ERC721Creator {
    constructor() ERC721Creator("Michael Stone Art", "MSODA") {}
}