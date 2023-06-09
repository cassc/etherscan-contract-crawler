// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Greg Younger Reader Rewards
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//      _                                              __  __      //
//     / _  _ _   _     \_) _       _   _     _   _    )_) )_)     //
//    (__/ ) )_) (_(     / (_) (_( ) ) (_(   )_) )    / \ / \      //
//          (_     _)                    _) (_                     //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract GYRR is ERC1155Creator {
    constructor() ERC1155Creator("Greg Younger Reader Rewards", "GYRR") {}
}