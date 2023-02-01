// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MYSTICS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    Hi all, I'm Vishwas,24, aka visualsby_v, I'm an artist and architect based in India.    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MYS is ERC721Creator {
    constructor() ERC721Creator("MYSTICS", "MYS") {}
}