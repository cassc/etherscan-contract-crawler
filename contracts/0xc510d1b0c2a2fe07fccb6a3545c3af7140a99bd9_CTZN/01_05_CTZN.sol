// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Citizen of No Place
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//       _________________   _   __    //
//      / ____/_  __/__  /  / | / /    //
//     / /     / /    / /  /  |/ /     //
//    / /___  / /    / /__/ /|  /      //
//    \____/ /_/    /____/_/ |_/       //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract CTZN is ERC1155Creator {
    constructor() ERC1155Creator("Citizen of No Place", "CTZN") {}
}