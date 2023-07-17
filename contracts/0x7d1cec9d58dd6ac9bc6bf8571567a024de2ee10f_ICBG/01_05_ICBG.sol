// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IKÉMEN COLLECTION: Blooming Garden -The Beginning-
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ====================================    //
//    =    ====     ===      =====      ==    //
//    ==  ====  ===  ==  ===  ===   ==   =    //
//    ==  ===  ========  ====  ==  ====  =    //
//    ==  ===  ========  ===  ===  =======    //
//    ==  ===  ========      ====  =======    //
//    ==  ===  ========  ===  ===  ===   =    //
//    ==  ===  ========  ====  ==  ====  =    //
//    ==  ====  ===  ==  ===  ===   ==   =    //
//    =    ====     ===      =====      ==    //
//    ====================================    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract ICBG is ERC1155Creator {
    constructor() ERC1155Creator(unicode"IKÉMEN COLLECTION: Blooming Garden -The Beginning-", "ICBG") {}
}