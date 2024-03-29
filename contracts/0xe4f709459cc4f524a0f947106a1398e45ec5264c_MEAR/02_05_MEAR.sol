// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pieces of Mear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//     _|_|_|    _|                                                            _|_|          //
//     _|    _|        _|_|      _|_|_|    _|_|      _|_|_|        _|_|      _|              //
//     _|_|_|    _|  _|_|_|_|  _|        _|_|_|_|  _|_|          _|    _|  _|_|_|_|          //
//     _|        _|  _|        _|        _|            _|_|      _|    _|    _|              //
//     _|        _|    _|_|_|    _|_|_|    _|_|_|  _|_|_|          _|_|      _|              //
//     _|      _|                                                                            //
//     _|_|  _|_|    _|_|      _|_|_|  _|  _|_|                                              //
//     _|  _|  _|  _|_|_|_|  _|    _|  _|_|                                                  //
//     _|      _|  _|        _|    _|  _|                                                    //
//     _|      _|    _|_|_|    _|_|_|  _|                                                    //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract MEAR is ERC721Creator {
    constructor() ERC721Creator("Pieces of Mear", "MEAR") {}
}