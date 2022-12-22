// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stafurskaya
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    Hello                                        //
//                                                 //
//    My name is Sofia and I’m digital artist.     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract STAF is ERC721Creator {
    constructor() ERC721Creator("Stafurskaya", "STAF") {}
}