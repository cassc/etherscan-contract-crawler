// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anonymous Nobody's Collector Claims
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//     _______________     //
//    |@@@@|     |####|    //
//    |@@@@|     |####|    //
//    |@@@@|     |####|    //
//    \@@@@|     |####/    //
//     \@@@|     |###/     //
//      `@@|_____|##'      //
//           (O)           //
//        .-'''''-.        //
//      .'  * * *  `.      //
//     :  *       *  :     //
//    : ~ C L A I M ~ :    //
//    : ~ * N F T * ~ :    //
//     :  *       *  :     //
//      `.  * * *  .'      //
//        `-.....-'        //
//                         //
//                         //
/////////////////////////////


contract CLAIM is ERC721Creator {
    constructor() ERC721Creator("Anonymous Nobody's Collector Claims", "CLAIM") {}
}