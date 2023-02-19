// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bifh
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    __________.___     //
//    \______   \   |    //
//     |    |  _/   |    //
//     |    |   \   |    //
//     |______  /___|    //
//            \/         //
//                       //
//                       //
///////////////////////////


contract BI is ERC721Creator {
    constructor() ERC721Creator("Bifh", "BI") {}
}