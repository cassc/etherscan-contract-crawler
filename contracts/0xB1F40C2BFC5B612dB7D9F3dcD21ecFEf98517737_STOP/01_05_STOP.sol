// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dailey Stop Motion
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ______      _ _            _   _     //
//    |  _  \    (_) |          | | (_)    //
//    | | | |__ _ _| | ___ _   _| |_ _     //
//    | | | / _` | | |/ _ \ | | | __| |    //
//    | |/ / (_| | | |  __/ |_| | |_| |    //
//    |___/ \__,_|_|_|\___|\__, |\__| |    //
//                          __/ |  _/ |    //
//                         |___/  |__/     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract STOP is ERC1155Creator {
    constructor() ERC1155Creator("Dailey Stop Motion", "STOP") {}
}