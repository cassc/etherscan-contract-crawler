// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Poppoppets Christmas Camping
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    This is a gift for poppoppets holder    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PPP is ERC721Creator {
    constructor() ERC721Creator("Poppoppets Christmas Camping", "PPP") {}
}