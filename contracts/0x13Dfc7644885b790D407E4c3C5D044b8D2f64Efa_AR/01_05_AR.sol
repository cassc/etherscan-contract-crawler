// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rachoksa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//       _____ __________     //
//      /  _  \\______   \    //
//     /  /_\  \|       _/    //
//    /    |    \    |   \    //
//    \____|__  /____|_  /    //
//            \/       \/     //
//                            //
//                            //
//                            //
////////////////////////////////


contract AR is ERC1155Creator {
    constructor() ERC1155Creator("rachoksa", "AR") {}
}