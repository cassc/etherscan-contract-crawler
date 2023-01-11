// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frog Affirmation Project
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//     +-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+    //
//     |F|A|P| |(|F|r|o|g| |A|f|f|i|r|m|a|t|i|o|n| |P|r|o|j|e|c|t|)|    //
//     +-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+    //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract FAP is ERC721Creator {
    constructor() ERC721Creator("Frog Affirmation Project", "FAP") {}
}