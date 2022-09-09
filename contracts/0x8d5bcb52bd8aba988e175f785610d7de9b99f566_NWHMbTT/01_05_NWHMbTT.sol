// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Home by Takens Theorem
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Welcome!                                   //
//    _  _ ____ _ _ _    _  _ ____ _  _ ____     //
//    |\ | |___ | | |    |__| |  | |\/| |___     //
//    | \| |___ |_|_|    |  | |__| |  | |___     //
//                                               //
//                         by Takens Theorem     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract NWHMbTT is ERC721Creator {
    constructor() ERC721Creator("New Home by Takens Theorem", "NWHMbTT") {}
}