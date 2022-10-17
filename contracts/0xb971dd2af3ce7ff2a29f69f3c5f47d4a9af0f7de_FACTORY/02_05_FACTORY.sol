// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Factory.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract FACTORY is ERC721Creator {
    constructor() ERC721Creator("Factory.", "FACTORY") {}
}