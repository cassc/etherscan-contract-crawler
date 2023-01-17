// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Look What I Found!!!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    looooooooooooooooooooooook!!!!!    //
//                                       //
//                                       //
///////////////////////////////////////////


contract lwif is ERC1155Creator {
    constructor() ERC1155Creator("Look What I Found!!!", "lwif") {}
}