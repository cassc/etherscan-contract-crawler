// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cradle of Era
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//       ******    *******   ********    //
//      **////**  **/////** /**/////     //
//     **    //  **     //**/**          //
//    /**       /**      /**/*******     //
//    /**       /**      /**/**////      //
//    //**    **//**     ** /**          //
//     //******  //*******  /********    //
//      //////    ///////   ////////     //
//                                       //
//                                       //
///////////////////////////////////////////


contract COE is ERC721Creator {
    constructor() ERC721Creator("Cradle of Era", "COE") {}
}