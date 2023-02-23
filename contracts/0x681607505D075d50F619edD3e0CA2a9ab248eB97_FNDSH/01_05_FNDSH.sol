// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life by 0xFiendish
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Editions and 1/1 art from 0xFiendish    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract FNDSH is ERC721Creator {
    constructor() ERC721Creator("Life by 0xFiendish", "FNDSH") {}
}