// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Birthday Girl
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    .___..       .__      , .    .        .__     .    //
//      |  |_  _   [__)*._.-+-|_  _| _.  .  [ __*._.|    //
//      |  [ )(/,  [__)|[   | [ )(_](_]\_|  [_./|[  |    //
//                                     ._|               //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TBG is ERC1155Creator {
    constructor() ERC1155Creator("The Birthday Girl", "TBG") {}
}