// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks-Elon Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    This art may or may not be verified.    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MUSK is ERC1155Creator {
    constructor() ERC1155Creator("Checks-Elon Edition", "MUSK") {}
}