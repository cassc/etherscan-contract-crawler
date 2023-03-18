// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Interactive Symphonies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ISPAISPA    //
//                //
//                //
////////////////////


contract ISPA is ERC721Creator {
    constructor() ERC721Creator("Interactive Symphonies", "ISPA") {}
}