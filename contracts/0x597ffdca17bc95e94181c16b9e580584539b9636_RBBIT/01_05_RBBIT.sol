// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FROGUE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    FROGUE - the most fake, most rare, most dank pepe mag on the planet.    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract RBBIT is ERC1155Creator {
    constructor() ERC1155Creator("FROGUE", "RBBIT") {}
}