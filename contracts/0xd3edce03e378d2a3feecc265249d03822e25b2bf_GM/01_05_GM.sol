// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gavin Meeler 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Gavin Meeler    //
//                    //
//                    //
////////////////////////


contract GM is ERC721Creator {
    constructor() ERC721Creator("Gavin Meeler 1/1s", "GM") {}
}