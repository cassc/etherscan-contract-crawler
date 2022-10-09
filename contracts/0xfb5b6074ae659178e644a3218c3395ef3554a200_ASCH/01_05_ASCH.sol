// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ASCH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//                                  //
//       ___    ____ _____ __ __    //
//      / _ |  / __// ___// // /    //
//     / __ | _\ \ / /__ / _  /     //
//    /_/ |_|/___/ \___//_//_/      //
//                                  //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract ASCH is ERC721Creator {
    constructor() ERC721Creator("ASCH", "ASCH") {}
}