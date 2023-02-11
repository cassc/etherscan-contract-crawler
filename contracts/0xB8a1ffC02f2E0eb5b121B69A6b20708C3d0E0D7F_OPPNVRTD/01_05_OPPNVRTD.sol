// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opepenverted Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{IIIIIIIIIII       {{IIIIIIIIIII       {{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{IIIIIIIIIII       {{IIIIIIIIIII       {{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{IIIIIIIIIII       {{IIIIIIIIIII       {{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{IIIIIIIIIII       {{IIIIIIIIIII       {{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII[ -------------------------------------- ]IIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIIIvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvIIIIIIIIIIIIIIIIIIIII    //
//    IIIIIIIIIIIIIIIIIII{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{IIIIIIIIIIIIIIIIIIIII    //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract OPPNVRTD is ERC1155Creator {
    constructor() ERC1155Creator("Opepenverted Edition", "OPPNVRTD") {}
}