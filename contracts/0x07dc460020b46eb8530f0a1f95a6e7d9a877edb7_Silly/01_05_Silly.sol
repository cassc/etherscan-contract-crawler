// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Silly land
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    All MEMES MATTER    //
//                        //
//                        //
////////////////////////////


contract Silly is ERC1155Creator {
    constructor() ERC1155Creator("Silly land", "Silly") {}
}