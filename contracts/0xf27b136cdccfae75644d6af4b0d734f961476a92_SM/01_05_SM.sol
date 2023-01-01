// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steven Morse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//    ____________  ______  _   _  _________________     //
//    [__  | |___|  ||___|\ |   |\/||  ||__/[__ |___     //
//    ___] | |___ \/ |___| \|   |  ||__||  \___]|___     //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract SM is ERC721Creator {
    constructor() ERC721Creator("Steven Morse", "SM") {}
}