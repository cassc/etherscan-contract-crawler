// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//      __       __  __     //
//     /_ |     / / /_ |    //
//      | |    / /   | |    //
//      | |   / /    | |    //
//      | |  / /     | |    //
//      |_| /_/      |_|    //
//                          //
//                          //
//////////////////////////////


contract onexone is ERC721Creator {
    constructor() ERC721Creator("1/1", "onexone") {}
}