// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Death & Cryptoart No. 2 - Pop Wonder
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//     +-+-+-+-+              //
//     |L|i|f|e|              //
//     +-+-+-+-+-+ +-+        //
//     |D|e|a|t|h| |&|        //
//     +-+-+-+-+-+-+-+-+-+    //
//     |C|r|y|p|t|o|a|r|t|    //
//     +-+-+-+-+-+-+-+-+-+    //
//                            //
//     No. 2 - Pop Wonder     //
//                            //
//                            //
////////////////////////////////


contract LDC2 is ERC1155Creator {
    constructor() ERC1155Creator("Life Death & Cryptoart No. 2 - Pop Wonder", "LDC2") {}
}