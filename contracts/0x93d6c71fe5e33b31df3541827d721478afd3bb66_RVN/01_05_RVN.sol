// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grant Riven Yun Early Works
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    Early Works (2016-2017) by Grant Riven Yun.                      //
//    Some of the first digital illustrations ever created by Yun.     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract RVN is ERC721Creator {
    constructor() ERC721Creator("Grant Riven Yun Early Works", "RVN") {}
}