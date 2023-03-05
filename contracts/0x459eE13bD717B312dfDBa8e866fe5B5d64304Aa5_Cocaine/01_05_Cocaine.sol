// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cocaine is Artdictive
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//      _|_|_|                                _|                          //
//    _|          _|_|      _|_|_|    _|_|_|      _|_|_|      _|_|        //
//    _|        _|    _|  _|        _|    _|  _|  _|    _|  _|_|_|_|      //
//    _|        _|    _|  _|        _|    _|  _|  _|    _|  _|            //
//      _|_|_|    _|_|      _|_|_|    _|_|_|  _|  _|    _|    _|_|_|      //
//                                                                        //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract Cocaine is ERC1155Creator {
    constructor() ERC1155Creator("Cocaine is Artdictive", "Cocaine") {}
}