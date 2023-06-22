// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Coastal Candy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    C O A S T A L / C A N D Y    //
//                                 //
//                                 //
/////////////////////////////////////


contract CANDY is ERC721Creator {
    constructor() ERC721Creator("Coastal Candy", "CANDY") {}
}