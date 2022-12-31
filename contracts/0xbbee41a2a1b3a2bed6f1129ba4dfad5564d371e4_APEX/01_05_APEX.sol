// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: APEX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    $APEX    //
//             //
//             //
/////////////////


contract APEX is ERC721Creator {
    constructor() ERC721Creator("APEX", "APEX") {}
}