// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FilmsCollection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    First Collection with films machine     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract FC1 is ERC721Creator {
    constructor() ERC721Creator("FilmsCollection", "FC1") {}
}