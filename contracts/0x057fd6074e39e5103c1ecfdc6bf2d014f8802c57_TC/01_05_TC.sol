// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trill Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    This artwork may or may not include a seedphrase     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract TC is ERC721Creator {
    constructor() ERC721Creator("Trill Checks", "TC") {}
}