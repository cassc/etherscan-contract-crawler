// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOYS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    ___________________ _____.___. _________    //
//    \__    ___/\_____  \\__  |   |/   _____/    //
//      |    |    /   |   \/   |   |\_____  \     //
//      |    |   /    |    \____   |/        \    //
//      |____|   \_______  / ______/_______  /    //
//                       \/\/              \/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract toys is ERC721Creator {
    constructor() ERC721Creator("TOYS", "toys") {}
}