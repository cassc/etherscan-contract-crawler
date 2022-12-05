// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy holidays 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    Happy holidays 2022    //
//                           //
//                           //
///////////////////////////////


contract HAPPYHOLIDAYS2022 is ERC721Creator {
    constructor() ERC721Creator("Happy holidays 2022", "HAPPYHOLIDAYS2022") {}
}