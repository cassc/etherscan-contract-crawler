// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: satto
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//         _        ,..      //
//     ,--._\\_.--, (-00)    //
//    ; #         _:(  -)    //
//    :          (_____/     //
//    :            :         //
//     '.___..___.`          //
//                           //
//                           //
///////////////////////////////


contract MSFT is ERC721Creator {
    constructor() ERC721Creator("satto", "MSFT") {}
}