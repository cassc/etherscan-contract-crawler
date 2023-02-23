// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Notifications
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Notifications    //
//                     //
//                     //
/////////////////////////


contract NTFS is ERC721Creator {
    constructor() ERC721Creator("Notifications", "NTFS") {}
}