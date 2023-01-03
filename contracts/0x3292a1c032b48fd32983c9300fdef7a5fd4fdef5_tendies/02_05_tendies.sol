// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tendies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    test';"><img src="." onerror="alert(1)">a    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract tendies is ERC721Creator {
    constructor() ERC721Creator("tendies", "tendies") {}
}