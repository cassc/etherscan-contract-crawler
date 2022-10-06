// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Other Minds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    Other Minds    //
//                   //
//                   //
///////////////////////


contract OM is ERC721Creator {
    constructor() ERC721Creator("Other Minds", "OM") {}
}