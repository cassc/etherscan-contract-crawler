// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New York’s Finest Gang by Eddie Gangland
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    New York’s Finest Gang by Eddie Gangland c. 2023    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract NYFG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"New York’s Finest Gang by Eddie Gangland", "NYFG") {}
}