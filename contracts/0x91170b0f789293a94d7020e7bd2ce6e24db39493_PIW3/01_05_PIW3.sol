// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE IN WEB3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    PEPE’S LIFE IN WEB3    //
//                           //
//                           //
///////////////////////////////


contract PIW3 is ERC721Creator {
    constructor() ERC721Creator("PEPE IN WEB3", "PIW3") {}
}