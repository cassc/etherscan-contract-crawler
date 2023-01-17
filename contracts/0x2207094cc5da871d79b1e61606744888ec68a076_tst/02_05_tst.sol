// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testtoburn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    fuzzman was here    //
//                        //
//                        //
////////////////////////////


contract tst is ERC1155Creator {
    constructor() ERC1155Creator("testtoburn", "tst") {}
}