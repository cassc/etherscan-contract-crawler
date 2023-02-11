// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LIFE IS A CASH GRAB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//       _     ____   ____       _      ____      //
//      | |   / ___| |  _ \     / \    | __ )     //
//     / __) | |  _  | |_) |   / _ \   |  _ \     //
//     \__ \ | |_| | |  _ <   / ___ \  | |_) |    //
//     (   /  \____| |_| \_\ /_/   \_\ |____/     //
//      |_|                                       //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract GRAB is ERC721Creator {
    constructor() ERC721Creator("LIFE IS A CASH GRAB", "GRAB") {}
}