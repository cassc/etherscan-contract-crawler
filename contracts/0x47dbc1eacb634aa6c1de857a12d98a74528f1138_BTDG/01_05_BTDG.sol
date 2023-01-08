// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bonka Truck: Degenerate Gambler
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    Ride in the Bonka i'm swerving--                                                   //
//                                                                                       //
//    Bonka Truck: Degenerate Gambler is a Manifold.xyz exclusive by @tonkatrucketh.     //
//                                                                                       //
//    An ode to being a degenerate.                                                      //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract BTDG is ERC721Creator {
    constructor() ERC721Creator("Bonka Truck: Degenerate Gambler", "BTDG") {}
}