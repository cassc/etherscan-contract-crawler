// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Test 721 Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    - - - - -    //
//                 //
//                 //
/////////////////////


contract GAS is ERC721Creator {
    constructor() ERC721Creator("My Test 721 Contract", "GAS") {}
}