// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEST 15
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    TEST15: MainNet Test    //
//                            //
//                            //
////////////////////////////////


contract TST15 is ERC721Creator {
    constructor() ERC721Creator("TEST 15", "TST15") {}
}