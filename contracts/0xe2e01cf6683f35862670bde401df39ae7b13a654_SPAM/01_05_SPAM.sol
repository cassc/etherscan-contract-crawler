// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SpamArt by Collin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    SpamArt by Collin Dyer collindyer.eth    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract SPAM is ERC1155Creator {
    constructor() ERC1155Creator("SpamArt by Collin", "SPAM") {}
}