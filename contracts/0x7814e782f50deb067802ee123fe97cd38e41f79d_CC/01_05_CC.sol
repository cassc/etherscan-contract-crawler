// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTO CAPSULES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    Special capsules for crypto addicts 💊    //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract CC is ERC721Creator {
    constructor() ERC721Creator("CRYPTO CAPSULES", "CC") {}
}