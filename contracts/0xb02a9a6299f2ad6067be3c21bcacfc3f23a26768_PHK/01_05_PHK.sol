// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PhenomHK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    PPPPPPPPPPP      H           H    K          K    //
//    P          P     H           H    K        K      //
//    P           P    H           H    K      K        //
//    P           P    H           H    K    K          //
//    P          P     H           H    K  K            //
//    PPPPPPPPPPP      HHHHHHHHHHHHH    KK              //
//    P                H           H    K  K            //
//    P                H           H    K    K          //
//    P                H           H    K      K        //
//    P                H           H    K        K      //
//    P                H           H    K          K    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract PHK is ERC1155Creator {
    constructor() ERC1155Creator("PhenomHK", "PHK") {}
}