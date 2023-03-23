// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primary_Process
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     ____ ____ ____ ____ ____ ____ ____     //
//    ||p |||r |||i |||m |||a |||r |||y ||    //
//    ||__|||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|/__\|    //
//    ||p |||r |||o |||c |||e |||s |||s ||    //
//    ||__|||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|/__\|    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract PMRY is ERC721Creator {
    constructor() ERC721Creator("Primary_Process", "PMRY") {}
}