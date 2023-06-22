// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: About Waves and Frequencies
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ˜˜˜˜    //
//            //
//            //
////////////////


contract AWF is ERC1155Creator {
    constructor() ERC1155Creator("About Waves and Frequencies", "AWF") {}
}