// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Homage
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    Homage to the art of the 20th century.                                                                                  //
//    That art, which was ahead of its time and which did not yet have enough technology to express itself to the fullest!    //
//    In part, I want to correct this injustice.                                                                              //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HMG is ERC1155Creator {
    constructor() ERC1155Creator("Homage", "HMG") {}
}