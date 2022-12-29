// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Swiggcaux Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
//        Yes, we are this fukt.          //
//                                        //
//                                        //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract SXE is ERC1155Creator {
    constructor() ERC1155Creator("Swiggcaux Editions", "SXE") {}
}