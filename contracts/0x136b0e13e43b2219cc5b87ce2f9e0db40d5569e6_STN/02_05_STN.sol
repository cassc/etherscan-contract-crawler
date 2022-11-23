// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SINTONIA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    +-+-+-+-+-+-+-+-+-+ +-+ +-+-+-+-+-+-+-+-+-+-+-+-+    //
//    |M|a|n|g|o|s|c|a|m| |x| |A|n|o|t|h|e|r|S|i|g|m|a|    //
//    +-+-+-+-+-+-+-+-+-+ +-+ +-+-+-+-+-+-+-+-+-+-+-+-+    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract STN is ERC721Creator {
    constructor() ERC721Creator("SINTONIA", "STN") {}
}