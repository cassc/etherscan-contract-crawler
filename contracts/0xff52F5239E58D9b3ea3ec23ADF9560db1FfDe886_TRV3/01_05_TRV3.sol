// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Rug | Vol. III
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     +-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+    //
//     |T|h|e| |R|u|g| |V|o|l|.| |I|I|I|    //
//     +-+-+-+ +-+-+-+ +-+-+-+-+ +-+-+-+    //
//                                          //
//                                          //
//////////////////////////////////////////////


contract TRV3 is ERC721Creator {
    constructor() ERC721Creator("The Rug | Vol. III", "TRV3") {}
}