// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBSCURITY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//       ___  ___ ___  ___ _   _ ___ ___ _______   __    //
//      / _ \| _ ) __|/ __| | | | _ \_ _|_   _\ \ / /    //
//     | (_) | _ \__ \ (__| |_| |   /| |  | |  \ V /     //
//      \___/|___/___/\___|\___/|_|_\___| |_|   |_|      //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract OBSCR is ERC721Creator {
    constructor() ERC721Creator("OBSCURITY", "OBSCR") {}
}