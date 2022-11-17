// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wecryptotogether
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    This is meme token for wecryptotogetherfan.    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract WCT is ERC721Creator {
    constructor() ERC721Creator("wecryptotogether", "WCT") {}
}