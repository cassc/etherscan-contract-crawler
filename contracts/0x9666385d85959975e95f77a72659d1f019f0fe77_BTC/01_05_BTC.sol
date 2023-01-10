// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blockchain Time  Coordinated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//    If you take good care of your time, it becomes more valuable.    //
//    Every minute matters.                                            //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract BTC is ERC721Creator {
    constructor() ERC721Creator("Blockchain Time  Coordinated", "BTC") {}
}