// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: American Reminiscence
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    American Reminiscence by Nathan A. Bauman    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract AMREM is ERC721Creator {
    constructor() ERC721Creator("American Reminiscence", "AMREM") {}
}