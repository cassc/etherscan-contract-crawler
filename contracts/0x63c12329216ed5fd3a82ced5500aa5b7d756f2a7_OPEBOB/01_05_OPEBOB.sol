// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Opebobs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//     O)oooo                  b)              b)                  //
//    O)    oo                 b)              b)                  //
//    O)    oo p)PPPP  e)EEEEE b)BBBB   o)OOO  b)BBBB   s)SSSS     //
//    O)    oo p)   PP e)EEEE  b)   BB o)   OO b)   BB s)SSSS      //
//    O)    oo p)   PP e)      b)   BB o)   OO b)   BB      s)     //
//     O)oooo  p)PPPP   e)EEEE b)BBBB   o)OOO  b)BBBB  s)SSSS      //
//             p)                                                  //
//             p)                                                  //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract OPEBOB is ERC721Creator {
    constructor() ERC721Creator("Opebobs", "OPEBOB") {}
}