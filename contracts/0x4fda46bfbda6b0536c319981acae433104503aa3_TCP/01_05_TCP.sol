// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheCelestialPass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    The Celestial Pass    //
//                          //
//                          //
//////////////////////////////


contract TCP is ERC1155Creator {
    constructor() ERC1155Creator("TheCelestialPass", "TCP") {}
}