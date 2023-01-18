// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cheeks ~ ASS Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Cheeks ~ ASS Edition    //
//                            //
//    By Shittoshit.eth       //
//                            //
//                            //
////////////////////////////////


contract CHEEKS is ERC721Creator {
    constructor() ERC721Creator("Cheeks ~ ASS Edition", "CHEEKS") {}
}