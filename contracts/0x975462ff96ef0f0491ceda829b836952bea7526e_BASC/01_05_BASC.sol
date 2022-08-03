// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Silhouette Club
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//      ____           _____  _____     //
//     |  _ \   /\    / ____|/ ____|    //
//     | |_) | /  \  | (___ | |         //
//     |  _ < / /\ \  \___ \| |         //
//     | |_) / ____ \ ____) | |____     //
//     |____/_/    \_\_____/ \_____|    //
//                                      //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract BASC is ERC721Creator {
    constructor() ERC721Creator("Bored Ape Silhouette Club", "BASC") {}
}