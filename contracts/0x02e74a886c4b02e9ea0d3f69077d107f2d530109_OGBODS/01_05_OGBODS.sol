// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoBordies Origins - Bodies
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    CRYPTOBORDIES ORIGINS - BODIES    //
//                                      //
//                                      //
//////////////////////////////////////////


contract OGBODS is ERC721Creator {
    constructor() ERC721Creator("CryptoBordies Origins - Bodies", "OGBODS") {}
}