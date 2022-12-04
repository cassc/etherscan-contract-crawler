// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Belly
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    __________       .__  .__             //
//    \______   \ ____ |  | |  | ___.__.    //
//     |    |  _// __ \|  | |  |<   |  |    //
//     |    |   \  ___/|  |_|  |_\___  |    //
//     |______  /\___  >____/____/ ____|    //
//            \/     \/          \/         //
//                                          //
//                                          //
//////////////////////////////////////////////


contract BL is ERC1155Creator {
    constructor() ERC1155Creator("Belly", "BL") {}
}