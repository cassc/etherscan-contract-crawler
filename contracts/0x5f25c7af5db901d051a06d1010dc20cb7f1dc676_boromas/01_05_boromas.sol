// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: boromas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    Thank you to all our supporters! Enjoy this free gift!    //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract boromas is ERC1155Creator {
    constructor() ERC1155Creator("boromas", "boromas") {}
}