// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ●
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//                ○                //
//          ○  ○  ○  ○  ○          //
//       ○  ○  ○  ○  ○  ○  ○       //
//       ○  ○  ○  ○  ○  ○  ○       //
//    ○  ○  ○  ○  ●  ○  ○  ○  ○    //
//       ○  ○  ○  ○  ○  ○  ○       //
//       ○  ○  ○  ○  ○  ○  ○       //
//          ○  ○  ○  ○  ○          //
//                ○                //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract FLM is ERC1155Creator {
    constructor() ERC1155Creator(unicode"●", "FLM") {}
}