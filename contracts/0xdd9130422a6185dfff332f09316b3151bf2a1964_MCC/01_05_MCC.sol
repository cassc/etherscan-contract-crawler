// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIC CHECK CHECKS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    🎤 MIC 🎤 CHECK 🎤 CHECKS 🎤    //
//                                    //
//                                    //
////////////////////////////////////////


contract MCC is ERC721Creator {
    constructor() ERC721Creator("MIC CHECK CHECKS", "MCC") {}
}