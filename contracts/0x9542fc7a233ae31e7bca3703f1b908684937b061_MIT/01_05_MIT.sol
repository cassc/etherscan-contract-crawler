// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: [MITSUBANA]
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//    [MITSUBANA] is a series of artworks drawn in theme of japanese folklore.                            //
//    It centers a titular character of living shintai (body of God), ranged from adolescent to adult.    //
//                                                                                                        //
//    Made by Nyaro/SaperlipopetteC, starting on July 2023.                                               //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIT is ERC1155Creator {
    constructor() ERC1155Creator("[MITSUBANA]", "MIT") {}
}