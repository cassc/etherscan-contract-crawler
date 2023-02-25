// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Batu Ergun
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    batu.    //
//             //
//             //
/////////////////


contract BATU is ERC721Creator {
    constructor() ERC721Creator("Batu Ergun", "BATU") {}
}