// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Capturing Value in Coffee
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//    Capturing Value in Coffee is a collaboration between Azahar Coffee Company, Ross Garlick, and Colombian Specialty Coffee Producers.    //
//                                                                                                                                           //
//    Events and NFTs created during Devcon 2022, Bogota.                                                                                    //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CVC is ERC721Creator {
    constructor() ERC721Creator("Capturing Value in Coffee", "CVC") {}
}