// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Whoareyou
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    who are you?    //
//                    //
//                    //
////////////////////////


contract WAY is ERC721Creator {
    constructor() ERC721Creator("Whoareyou", "WAY") {}
}