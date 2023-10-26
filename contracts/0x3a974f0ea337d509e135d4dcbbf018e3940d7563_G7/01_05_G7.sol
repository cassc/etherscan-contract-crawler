// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Living with the ancients
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    I decided to create the most beautiful ones with old arts    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract G7 is ERC1155Creator {
    constructor() ERC1155Creator("Living with the ancients", "G7") {}
}