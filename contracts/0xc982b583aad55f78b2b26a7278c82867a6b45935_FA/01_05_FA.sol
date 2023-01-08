// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fioreeza
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    A collection contains Fioreeza illustrations    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract FA is ERC721Creator {
    constructor() ERC721Creator("Fioreeza", "FA") {}
}