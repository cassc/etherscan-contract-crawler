// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Commission Akije
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    <<A collection with my various commissions.>>    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract COAKI is ERC721Creator {
    constructor() ERC721Creator("Commission Akije", "COAKI") {}
}