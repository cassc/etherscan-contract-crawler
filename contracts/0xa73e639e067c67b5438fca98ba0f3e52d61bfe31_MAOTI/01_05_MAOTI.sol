// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Art over the time
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//     +-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+    //
//     |M|y| |A|r|t| |o|v|e|r| |t|h|e| |t|i|m|e|    //
//     +-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract MAOTI is ERC721Creator {
    constructor() ERC721Creator("My Art over the time", "MAOTI") {}
}