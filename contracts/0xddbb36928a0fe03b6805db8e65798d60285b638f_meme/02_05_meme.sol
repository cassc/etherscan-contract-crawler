// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MemeGene
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//     _, _ __, _, _ __,    _, __, _, _ __,    //
//     |\/| |_  |\/| |_    / _ |_  |\ | |_     //
//     |  | |   |  | |     \ / |   | \| |      //
//     ~  ~ ~~~ ~  ~ ~~~    ~  ~~~ ~  ~ ~~~    //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract meme is ERC1155Creator {
    constructor() ERC1155Creator("MemeGene", "meme") {}
}