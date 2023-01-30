// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Start
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    I hope that our design can be influential and inspiring in various fields, not just blind pursuit of utilitarianism.    //
//    Experimental creation is a way to find and experience life.                                                             //
//                                                                                                                            //
//    There is actually only a thin line between design and art.                                                              //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract art is ERC1155Creator {
    constructor() ERC1155Creator("Start", "art") {}
}