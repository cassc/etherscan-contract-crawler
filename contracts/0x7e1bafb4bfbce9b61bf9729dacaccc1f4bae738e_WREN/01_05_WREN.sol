// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wrencrypt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                   _       //
//    __      ___ __ ___ _ __   ___ _ __ _   _ _ __ | |_     //
//    \ \ /\ / / '__/ _ \ '_ \ / __| '__| | | | '_ \| __|    //
//     \ V  V /| | |  __/ | | | (__| |  | |_| | |_) | |_     //
//      \_/\_/ |_|  \___|_| |_|\___|_|   \__, | .__/ \__|    //
//                                        __/ | |            //
//                                       |___/|_|            //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract WREN is ERC721Creator {
    constructor() ERC721Creator("wrencrypt", "WREN") {}
}