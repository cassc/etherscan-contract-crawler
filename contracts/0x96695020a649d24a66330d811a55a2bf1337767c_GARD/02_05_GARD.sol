// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GARDEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    |__) |__) /  \  |   /\  |   |_   |  |__|     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract GARD is ERC721Creator {
    constructor() ERC721Creator("GARDEN", "GARD") {}
}