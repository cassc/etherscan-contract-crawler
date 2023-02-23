// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magic Key
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    HomeRenovationNation.com    //
//                                //
//                                //
////////////////////////////////////


contract MK is ERC721Creator {
    constructor() ERC721Creator("Magic Key", "MK") {}
}