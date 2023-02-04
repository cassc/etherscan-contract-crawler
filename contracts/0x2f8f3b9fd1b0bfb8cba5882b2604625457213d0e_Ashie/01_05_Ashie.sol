// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ashiellee.eth
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    Exploring Manifold for new adventure!    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract Ashie is ERC1155Creator {
    constructor() ERC1155Creator("Ashiellee.eth", "Ashie") {}
}