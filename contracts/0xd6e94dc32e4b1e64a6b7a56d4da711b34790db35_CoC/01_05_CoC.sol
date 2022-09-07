// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Children of Coal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Photographer    //
//                    //
//                    //
////////////////////////


contract CoC is ERC721Creator {
    constructor() ERC721Creator("Children of Coal", "CoC") {}
}