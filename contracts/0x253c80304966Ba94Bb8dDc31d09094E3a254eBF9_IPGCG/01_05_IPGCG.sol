// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IPG Champions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//     (   (                //
//     )\ ))\ ) (           //
//    (()/(()/( )\ )        //
//     /(_))(_)|()/(        //
//    (_))(_))  /(_))_      //
//    |_ _| _ \(_)) __|     //
//     | ||  _/  | (_ |     //
//    |___|_|     \___|     //
//                          //
//                          //
//                          //
//////////////////////////////


contract IPGCG is ERC1155Creator {
    constructor() ERC1155Creator("IPG Champions", "IPGCG") {}
}