// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PLANTTDADDII.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    planttdaddii.com                                                                    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PLANT is ERC1155Creator {
    constructor() ERC1155Creator("PLANTTDADDII.", "PLANT") {}
}