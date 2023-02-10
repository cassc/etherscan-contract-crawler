// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not an Ordinal
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    <>This is not an Ordinal    //
//                                //
//                                //
////////////////////////////////////


contract FKORD is ERC721Creator {
    constructor() ERC721Creator("Not an Ordinal", "FKORD") {}
}