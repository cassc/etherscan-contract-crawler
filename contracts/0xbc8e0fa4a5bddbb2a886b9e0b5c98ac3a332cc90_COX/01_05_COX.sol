// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE PATH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    CRUNCHYOREOX    //
//                    //
//                    //
////////////////////////


contract COX is ERC721Creator {
    constructor() ERC721Creator("THE PATH", "COX") {}
}