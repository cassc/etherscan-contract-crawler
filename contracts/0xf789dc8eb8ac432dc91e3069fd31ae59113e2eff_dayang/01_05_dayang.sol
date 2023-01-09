// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yangyang
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//    identify your contract, and it looks really cool. Take a moment to pick out some meaningful ASCII art that represents your work, identity, and creativity.    //
//                                                                                                                                                                  //
//                                                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract dayang is ERC721Creator {
    constructor() ERC721Creator("yangyang", "dayang") {}
}