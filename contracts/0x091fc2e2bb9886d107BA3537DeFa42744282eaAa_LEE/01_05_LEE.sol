// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LEE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Be Water, My Friend.    //
//                            //
//                            //
////////////////////////////////


contract LEE is ERC1155Creator {
    constructor() ERC1155Creator("LEE", "LEE") {}
}