// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Takedown By. Tsutomu Shimomura
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     (o)__(o)(o)__(o) oo_        //
//     (__  __)(__  __)/  _)-<     //
//       (  )    (  )  \__ `.      //
//        )(      )(      `. |     //
//       (  )    (  )     _| |     //
//        )/      )/   ,-'   |     //
//       (       (    (_..--'      //
//                                 //
//                                 //
/////////////////////////////////////


contract TTS is ERC1155Creator {
    constructor() ERC1155Creator("Takedown By. Tsutomu Shimomura", "TTS") {}
}