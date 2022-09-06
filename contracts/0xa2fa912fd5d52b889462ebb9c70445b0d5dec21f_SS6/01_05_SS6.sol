// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SS61111
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    SS6 is the dark side of light and the light side of dark...    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract SS6 is ERC721Creator {
    constructor() ERC721Creator("SS61111", "SS6") {}
}