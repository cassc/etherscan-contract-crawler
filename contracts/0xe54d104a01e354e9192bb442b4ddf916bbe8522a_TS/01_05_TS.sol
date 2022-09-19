// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tyas
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    _/_/_/_/_/  _/      _/    _/_/      _/_/_/       //
//       _/        _/  _/    _/    _/  _/              //
//      _/          _/      _/_/_/_/    _/_/           //
//     _/          _/      _/    _/        _/          //
//    _/          _/      _/    _/  _/_/_/             //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract TS is ERC721Creator {
    constructor() ERC721Creator("Tyas", "TS") {}
}