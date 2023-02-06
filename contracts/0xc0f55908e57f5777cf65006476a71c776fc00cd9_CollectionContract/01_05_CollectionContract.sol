// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CollectionContract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//     .-.;;;;;;'                       //
//    (_)  .;                           //
//         : .-.       .;.::..-.        //
//       .:';   :      .;   ;   :       //
//     .-:._`:::'-'  .;'    `:::'-'     //
//    (_/  `-                           //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract CollectionContract is ERC721Creator {
    constructor() ERC721Creator("CollectionContract", "CollectionContract") {}
}