// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RiverRyan 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//            ..  ..   / o._)                   .---.           //
//           /--'/--\  \-'||        .----.    .'     '.         //
//          /        \_/ / |      .'      '..'         '-.RR    //
//        .'\  \__\  __.'.'     .'          ._                  //
//          )\ |  )\ |      _.'                                 //
//         // \\ // \\                                          //
//        ||_  \\|_  \\_                                        //
//        '--' '--'' '--'                                       //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract RR1 is ERC721Creator {
    constructor() ERC721Creator("RiverRyan 1/1", "RR1") {}
}