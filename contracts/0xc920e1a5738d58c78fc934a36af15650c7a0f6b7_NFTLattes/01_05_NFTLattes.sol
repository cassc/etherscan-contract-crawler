// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Lattes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    )  (                //
//         (   ) )        //
//          ) ( (         //
//        (_______)_      //
//     .-'---------|      //
//    ( C|/\/\/\/\/|      //
//     '-./\/\/\/\/|      //
//       '_________'      //
//        '-------'       //
//                        //
//                        //
////////////////////////////


contract NFTLattes is ERC721Creator {
    constructor() ERC721Creator("NFT Lattes", "NFTLattes") {}
}