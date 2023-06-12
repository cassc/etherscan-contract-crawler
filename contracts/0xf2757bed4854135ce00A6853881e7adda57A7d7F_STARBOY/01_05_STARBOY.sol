// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Starboy ED by Hud Velvet
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//      _  _         _       __   __   _         _       //
//     | || |_  _ __| |__ _  \ \ / /__| |_ _____| |_     //
//     | __ | || / _` / _` |  \ V / -_) \ V / -_)  _|    //
//     |_||_|\_,_\__,_\__,_|   \_/\___|_|\_/\___|\__|    //
//                                                       //
//      All rights reserved © Huda Velvet 2023           //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract STARBOY is ERC1155Creator {
    constructor() ERC1155Creator("Starboy ED by Hud Velvet", "STARBOY") {}
}