// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Air Jesus Signed Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    AJSE    //
//            //
//            //
////////////////


contract AJSE is ERC721Creator {
    constructor() ERC721Creator("Air Jesus Signed Edition", "AJSE") {}
}