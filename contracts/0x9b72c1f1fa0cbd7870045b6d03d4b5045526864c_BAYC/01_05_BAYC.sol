// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gladiator BBC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    in question    //
//                   //
//                   //
///////////////////////


contract BAYC is ERC721Creator {
    constructor() ERC721Creator("Gladiator BBC", "BAYC") {}
}