// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beatcoin Vol1.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     _____ _____  _____   ____  _____      //
//    |_   _|  __ \|  __ \ / __ \|  __ \     //
//      | | | |  | | |  | | |  | | |  | |    //
//      | | | |  | | |  | | |  | | |  | |    //
//     _| |_| |__| | |__| | |__| | |__| |    //
//    |_____|_____/|_____/ \___\_\_____/     //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract IDDQD is ERC1155Creator {
    constructor() ERC1155Creator("Beatcoin Vol1.", "IDDQD") {}
}