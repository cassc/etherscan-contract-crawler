// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Don't Look Back
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Don't Look Back    //
//                       //
//                       //
///////////////////////////


contract DLB is ERC721Creator {
    constructor() ERC721Creator("Don't Look Back", "DLB") {}
}