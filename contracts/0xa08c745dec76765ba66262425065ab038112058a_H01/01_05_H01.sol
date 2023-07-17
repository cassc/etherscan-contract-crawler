// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: H01
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     __    __    ___    __      //
//    |  |  |  |  / _ \  /_ |     //
//    |  |__|  | | | | |  | |     //
//    |   __   | | | | |  | |     //
//    |  |  |  | | |_| |  | |     //
//    |__|  |__|  \___/   |_|     //
//                                //
//                                //
//                                //
////////////////////////////////////


contract H01 is ERC721Creator {
    constructor() ERC721Creator("H01", "H01") {}
}