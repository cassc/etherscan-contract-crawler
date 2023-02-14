// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toki no Ne
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    catfish xxx Toki no Ne    //
//                              //
//                              //
//////////////////////////////////


contract TN is ERC721Creator {
    constructor() ERC721Creator("Toki no Ne", "TN") {}
}