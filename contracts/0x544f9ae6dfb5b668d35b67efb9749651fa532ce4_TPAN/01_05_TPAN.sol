// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testPancopa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    🐈🥐🐈🥐🐈🥐🐈🥐🐈🥐🐈🥐🐈🥐    //
//                                    //
//                                    //
////////////////////////////////////////


contract TPAN is ERC1155Creator {
    constructor() ERC1155Creator("testPancopa", "TPAN") {}
}