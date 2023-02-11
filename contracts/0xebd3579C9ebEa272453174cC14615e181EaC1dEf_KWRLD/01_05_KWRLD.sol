// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karak World
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     +-+-+-+-+-+ +-+-+-+-+-+    //
//     |K|A|R|A|K| |W|O|R|L|D|    //
//     +-+-+-+-+-+ +-+-+-+-+-+    //
//         By - Abdulla           //
//                                //
//                                //
////////////////////////////////////


contract KWRLD is ERC1155Creator {
    constructor() ERC1155Creator("Karak World", "KWRLD") {}
}