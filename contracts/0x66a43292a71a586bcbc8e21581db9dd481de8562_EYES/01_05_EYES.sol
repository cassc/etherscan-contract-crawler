// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof Of Existence Series
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    [- `/ [- _\~   () /=   _\~ | |_| |_    //
//                                           //
//                                           //
///////////////////////////////////////////////


contract EYES is ERC721Creator {
    constructor() ERC721Creator("Proof Of Existence Series", "EYES") {}
}