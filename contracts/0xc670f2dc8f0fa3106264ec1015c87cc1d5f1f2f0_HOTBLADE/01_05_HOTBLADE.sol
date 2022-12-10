// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blade
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//      ____  _           _          //
//     |  _ \| |         | |         //
//     | |_) | | __ _  __| | ___     //
//     |  _ <| |/ _` |/ _` |/ _ \    //
//     | |_) | | (_| | (_| |  __/    //
//     |____/|_|\__,_|\__,_|\___|    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract HOTBLADE is ERC1155Creator {
    constructor() ERC1155Creator("Blade", "HOTBLADE") {}
}