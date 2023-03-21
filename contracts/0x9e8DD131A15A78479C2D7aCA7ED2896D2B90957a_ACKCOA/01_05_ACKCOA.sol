// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Interactive Certificates Of Authenticity
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    This Contract is for my physical works. Interactive Certificates Of Authenticity      //
//    have the ability to show us historical provenance which might otherwise be hard       //
//    to find. These CoA's must remain coupled with their physical counterparts and are     //
//    not intended for individual sale. Thank you for caring about my art.                  //
//                                                                                          //
//                                                          Developed by ACK + Yungwknd     //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract ACKCOA is ERC721Creator {
    constructor() ERC721Creator("Interactive Certificates Of Authenticity", "ACKCOA") {}
}