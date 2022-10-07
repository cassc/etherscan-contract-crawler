// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TestERC721 for MJ
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    01001101 01000001 01001010 01001001 01001110     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MJ721 is ERC721Creator {
    constructor() ERC721Creator("TestERC721 for MJ", "MJ721") {}
}