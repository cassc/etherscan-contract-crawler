// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BatDad
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//      ____        _   _____            _     //
//     |  _ \      | | |  __ \          | |    //
//     | |_) | __ _| |_| |  | | __ _  __| |    //
//     |  _ < / _` | __| |  | |/ _` |/ _` |    //
//     | |_) | (_| | |_| |__| | (_| | (_| |    //
//     |____/ \__,_|\__|_____/ \__,_|\__,_|    //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract BD is ERC721Creator {
    constructor() ERC721Creator("BatDad", "BD") {}
}