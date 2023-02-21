// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Super Opepen Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//              ___              //
//            ,"---".            //
//            :     ;            //
//             `-.-'             //
//              | |              //
//              | |              //
//              | |              //
//           _.-\_/-._           //
//        _ / |     | \ _        //
//       / /   `---'   \ \       //
//      /  `-----------'  \      //
//     /,-""-.       ,-""-.\     //
//    ( i-..-i       i-..-i )    //
//    |`|    |-------|    |'|    //
//    \ `-..-'  ,=.  `-..-'/     //
//     `--------|=|-------'      //
//              | |              //
//              \ \              //
//               ) )             //
//              / /              //
//             ( (               //
//                               //
//                               //
///////////////////////////////////


contract SOPEPEN is ERC1155Creator {
    constructor() ERC1155Creator("Super Opepen Edition", "SOPEPEN") {}
}