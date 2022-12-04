// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOLIKAO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//     +-+-+-+-+-+-+-+    //
//     |H|O|L|I|K|A|O|    //
//     +-+-+-+-+-+-+-+    //
//                        //
//                        //
////////////////////////////


contract KAO is ERC721Creator {
    constructor() ERC721Creator("HOLIKAO", "KAO") {}
}