// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mark Constantine Inducil 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Mark Constantine Inducil    //
//    ░░░░░░░░░░░░░░░░░░░░░░░░    //
//    1/1                         //
//    ░░░░░░░░░░░░░░░░░░░░░░░░    //
//    www.markinducil.com         //
//                                //
//                                //
////////////////////////////////////


contract MCI1 is ERC721Creator {
    constructor() ERC721Creator("Mark Constantine Inducil 1/1", "MCI1") {}
}