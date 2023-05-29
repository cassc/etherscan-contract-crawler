// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FantasticIllusions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//     __ __  __ __     //
//    |  |  ||  |  |    //
//    |  |  ||  |  |    //
//    |  ~  ||  |  |    //
//    |___, ||  :  |    //
//    |     ||     |    //
//    |____/  \__,_|    //
//                      //
//                      //
//                      //
//                      //
//////////////////////////


contract FTIL is ERC721Creator {
    constructor() ERC721Creator("FantasticIllusions", "FTIL") {}
}