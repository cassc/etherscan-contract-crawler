// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SmugbunnyHeartsShontelle
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    SmugbunnyHeartsShontelle    //
//                                //
//                                //
////////////////////////////////////


contract SHS is ERC1155Creator {
    constructor() ERC1155Creator("SmugbunnyHeartsShontelle", "SHS") {}
}