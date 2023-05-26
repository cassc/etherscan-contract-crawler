// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VOICE GEMS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     \· . _ .·/   \·._ .·/        //
//      '\      /'  .·´   .·´'      //
//        \    `·´   .·´    '       //
//         '\     .·´               //
//           \.·´'                  //
//                                  //
//                                  //
//////////////////////////////////////


contract VG is ERC721Creator {
    constructor() ERC721Creator("VOICE GEMS", "VG") {}
}