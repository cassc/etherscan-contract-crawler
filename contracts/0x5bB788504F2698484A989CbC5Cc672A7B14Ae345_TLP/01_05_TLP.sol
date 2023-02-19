// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B4EVExxxxxx
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//      _____________  __.____ ___.____    .____         //
//     /   _____/    |/ _|    |   \    |   |    |        //
//     \_____  \|      < |    |   /    |   |    |        //
//     /        \    |  \|    |  /|    |___|    |___     //
//    /_______  /____|__ \______/ |_______ \_______ \    //
//            \/        \/                \/       \/    //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract TLP is ERC1155Creator {
    constructor() ERC1155Creator("B4EVExxxxxx", "TLP") {}
}