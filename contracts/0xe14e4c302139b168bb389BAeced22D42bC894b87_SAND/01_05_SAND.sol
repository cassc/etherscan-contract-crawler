// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Simply Anders
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Simply Anders    //
//                     //
//                     //
//                     //
/////////////////////////


contract SAND is ERC721Creator {
    constructor() ERC721Creator("Simply Anders", "SAND") {}
}