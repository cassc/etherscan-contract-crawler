// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Efremova-2 Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    EFREMOVA    //
//                //
//                //
////////////////////


contract EFRESH is ERC721Creator {
    constructor() ERC721Creator("Efremova-2 Editions", "EFRESH") {}
}