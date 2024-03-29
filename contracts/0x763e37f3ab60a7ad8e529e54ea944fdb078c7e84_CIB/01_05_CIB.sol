// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colors In Black
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//                                        _|        _|  _|  _|                          //
//    _|_|_|  _|_|      _|_|_|    _|_|_|  _|_|_|        _|  _|  _|    _|  _|    _|      //
//    _|    _|    _|  _|    _|  _|        _|    _|  _|  _|  _|  _|    _|    _|_|        //
//    _|    _|    _|  _|    _|  _|        _|    _|  _|  _|  _|  _|    _|  _|    _|      //
//    _|    _|    _|    _|_|_|    _|_|_|  _|    _|  _|  _|  _|    _|_|_|  _|    _|      //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract CIB is ERC721Creator {
    constructor() ERC721Creator("Colors In Black", "CIB") {}
}