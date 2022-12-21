// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: blinded by darkness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     ____  ____  ____  _  __ _      _____ ____  ____       //
//    /  _ \/  _ \/  __\/ |/ // \  /|/  __// ___\/ ___\      //
//    | | \|| / \||  \/||   / | |\ |||  \  |    \|    \      //
//    | |_/|| |-|||    /|   \ | | \|||  /_ \___ |\___ |      //
//    \____/\_/ \|\_/\_\\_|\_\\_/  \|\____\\____/\____/      //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract bbd is ERC1155Creator {
    constructor() ERC1155Creator("blinded by darkness", "bbd") {}
}