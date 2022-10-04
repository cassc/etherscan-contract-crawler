// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EX: honey b.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    This album is all about vibing and relaxing. It's perfect for kicking back and letting the stresses of the day melt away. The mellow instrumentals will transport you to a place of peace and tranquility, where you can just let go and be in the moment. Whether you're looking to wind down after a long day or just need a break from the hustle and bustle, this album is perfect for finding your zen.    //
//                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HONEY is ERC721Creator {
    constructor() ERC721Creator("EX: honey b.", "HONEY") {}
}