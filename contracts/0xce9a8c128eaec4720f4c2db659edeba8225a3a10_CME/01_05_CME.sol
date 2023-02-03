// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CM Editions- 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    2023 Landscape PhotographyEditions by Caleb McKenney    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract CME is ERC1155Creator {
    constructor() ERC1155Creator("CM Editions- 2023", "CME") {}
}