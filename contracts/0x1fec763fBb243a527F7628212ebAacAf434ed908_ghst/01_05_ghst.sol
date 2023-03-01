// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ghostvibing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//           _         _         _                     //
//      __ _| |__  ___| |___   _| |__  _ __   __ _     //
//     / _` | '_ \/ __| __\ \ / / '_ \| '_ \ / _` |    //
//    | (_| | | | \__ \ |_ \ V /| |_) | | | | (_| |    //
//     \__, |_| |_|___/\__| \_/ |_.__/|_| |_|\__, |    //
//     |___/                                 |___/     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract ghst is ERC721Creator {
    constructor() ERC721Creator("Ghostvibing", "ghst") {}
}