// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Our life
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    The prison in our house.    //
//                                //
//                                //
////////////////////////////////////


contract OL is ERC1155Creator {
    constructor() ERC1155Creator("Our life", "OL") {}
}