// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Natali Gorskaya
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     ____ ____ ____ ____ ____ ____ ____ ____     //
//    ||G |||o |||r |||s |||k |||a |||y |||a ||    //
//    ||__|||__|||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract NGart is ERC721Creator {
    constructor() ERC721Creator("Natali Gorskaya", "NGart") {}
}