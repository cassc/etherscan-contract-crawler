// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magic Carpet Rug Exchange
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    Exchange your rugs at the Magic Carpet Rug Exchange    //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract MCRE is ERC1155Creator {
    constructor() ERC1155Creator("Magic Carpet Rug Exchange", "MCRE") {}
}