// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The PACKAGE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//     +-+-+-+-+ +-+-+-+-+-+ +-+-+ +-+-+-+    //
//     |W|h|a|t| |C|o|u|l|d| |I|t| |B|e|?|    //
//     +-+-+-+-+ +-+-+-+-+-+ +-+-+ +-+-+-+    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract ThPKG is ERC1155Creator {
    constructor() ERC1155Creator("The PACKAGE", "ThPKG") {}
}