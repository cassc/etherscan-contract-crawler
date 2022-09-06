// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sally Boy Five
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    Sally and his Boys unite for World peace among other things    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract SB5 is ERC721Creator {
    constructor() ERC721Creator("Sally Boy Five", "SB5") {}
}