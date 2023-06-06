// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Death & Cryptoart No. 5 - Reylarsdam
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
//     No. 5 - Reylarsdam     //
//                            //
//                            //
////////////////////////////////


contract LDC5 is ERC1155Creator {
    constructor() ERC1155Creator("Life Death & Cryptoart No. 5 - Reylarsdam", "LDC5") {}
}