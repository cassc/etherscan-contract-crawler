// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IKÉMEN COLLECTION: Blooming Garden -Gift-
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract ICBG is ERC721Creator {
    constructor() ERC721Creator(unicode"IKÉMEN COLLECTION: Blooming Garden -Gift-", "ICBG") {}
}