// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merge Day Solarpunk Daydreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    (¯`·¯`·.¸¸.·´¯`·.¸¸.·´¯`·.¸¸.·´¯`·.¸¸·´¯)    //
//    ( \                                   / )    //
//     ( ) ~Merge Day Solarpunk Daydreams~ ( )     //
//      (/                                 \)      //
//       (.·´¯`·.¸¸.·´¯`·.¸¸.·´¯`·.¸¸.·´¯`·)       //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MDSD is ERC721Creator {
    constructor() ERC721Creator("Merge Day Solarpunk Daydreams", "MDSD") {}
}