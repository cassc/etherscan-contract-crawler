// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blues Project
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Blue Project    //
//                    //
//                    //
////////////////////////


contract BlueProject is ERC721Creator {
    constructor() ERC721Creator("Blues Project", "BlueProject") {}
}