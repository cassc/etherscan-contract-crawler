// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vin D'honneur
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-. .-.-.      //
//    '. I )'. L )'. L )'. U )'. S )'. I )'. O )'. N )'. S )     //
//      ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'   ).'      //
//                                                               //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract EKN is ERC721Creator {
    constructor() ERC721Creator("Vin D'honneur", "EKN") {}
}