// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Happy New Year 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    happy new year 2023    //
//                           //
//                           //
///////////////////////////////


contract bokehpanther is ERC1155Creator {
    constructor() ERC1155Creator("Happy New Year 2023", "bokehpanther") {}
}