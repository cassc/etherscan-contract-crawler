// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ok-ex
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    ok-ex.io    //
//                //
//                //
////////////////////


contract okex is ERC721Creator {
    constructor() ERC721Creator("Ok-ex", "okex") {}
}