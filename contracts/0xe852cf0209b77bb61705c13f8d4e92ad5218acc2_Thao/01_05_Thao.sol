// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ThaoNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    _/_/_/_/_/  _/    _/    _/_/      _/_/        //
//       _/      _/    _/  _/    _/  _/    _/       //
//      _/      _/_/_/_/  _/_/_/_/  _/    _/        //
//     _/      _/    _/  _/    _/  _/    _/         //
//    _/      _/    _/  _/    _/    _/_/            //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Thao is ERC721Creator {
    constructor() ERC721Creator("ThaoNFT", "Thao") {}
}