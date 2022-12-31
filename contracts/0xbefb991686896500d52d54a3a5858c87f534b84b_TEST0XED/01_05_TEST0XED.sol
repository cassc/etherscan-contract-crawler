// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test 0xed
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    _____            _____     //
//    __  /______________  /_    //
//    _  __/  _ \_  ___/  __/    //
//    / /_ /  __/(__  )/ /_      //
//    \__/ \___//____/ \__/      //
//                               //
//                               //
//                               //
///////////////////////////////////


contract TEST0XED is ERC721Creator {
    constructor() ERC721Creator("Test 0xed", "TEST0XED") {}
}