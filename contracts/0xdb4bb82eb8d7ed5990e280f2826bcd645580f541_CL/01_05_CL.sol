// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cocoa Love
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    The Mayans believed chocolate elixirs to be Food of the Gods.    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract CL is ERC721Creator {
    constructor() ERC721Creator("Cocoa Love", "CL") {}
}