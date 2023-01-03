// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NonFungibleBae
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//             ___..._         //
//        _,--'       "`-.     //
//      ,'o  o            \    //
//    ,/o o     o       .'     //
//    |oo  o      _..--'       //
//    `--:...-,-'""\           //
//            |:.  `.          //
//            l;.   l          //
//            `|:.   |         //
//             |:.   `.,       //
//            .l;.    j, ,     //
//         `. \`;:.   //,/     //
//          .\\)`;,|\'/(       //
//           ` `,\/`(,         //
//                             //
//                             //
/////////////////////////////////


contract MAGIC is ERC721Creator {
    constructor() ERC721Creator("NonFungibleBae", "MAGIC") {}
}