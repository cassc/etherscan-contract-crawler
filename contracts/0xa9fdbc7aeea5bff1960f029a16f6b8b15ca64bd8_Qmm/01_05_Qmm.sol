// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: QuintaM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    QuintaM     //
//                //
//                //
////////////////////


contract Qmm is ERC721Creator {
    constructor() ERC721Creator("QuintaM", "Qmm") {}
}