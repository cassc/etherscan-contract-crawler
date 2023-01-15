// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Works 2023 by Narada
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//       _/      _/  _/          _/    _/_/    _/_/_/         //
//       _/_/    _/  _/          _/  _/    _/        _/       //
//      _/  _/  _/  _/    _/    _/      _/      _/_/          //
//     _/    _/_/    _/  _/  _/      _/            _/         //
//    _/      _/      _/  _/      _/_/_/_/  _/_/_/            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract NW23 is ERC1155Creator {
    constructor() ERC1155Creator("Works 2023 by Narada", "NW23") {}
}