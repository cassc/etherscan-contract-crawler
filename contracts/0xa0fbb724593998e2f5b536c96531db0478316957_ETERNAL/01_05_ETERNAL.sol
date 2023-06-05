// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternal Voyage
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//     ___ ___  ___  __                          __            __   ___     //
//    |__   |  |__  |__) |\ |  /\  |       \  / /  \ \ /  /\  / _` |__      //
//    |___  |  |___ |  \ | \| /~~\ |___     \/  \__/  |  /~~\ \__> |___     //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract ETERNAL is ERC1155Creator {
    constructor() ERC1155Creator("Eternal Voyage", "ETERNAL") {}
}