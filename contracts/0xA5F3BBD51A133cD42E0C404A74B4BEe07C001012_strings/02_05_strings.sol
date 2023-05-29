// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STRINGS :::..._I ••°|_...] _ [  editions ]
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                 _|                _|                                    //
//       _|_|_|  _|_|_|_|  _|  _|_|      _|_|_|      _|_|_|    _|_|_|      //
//     _|_|        _|      _|_|      _|  _|    _|  _|    _|  _|_|          //
//         _|_|    _|      _|        _|  _|    _|  _|    _|      _|_|      //
//     _|_|_|        _|_|  _|        _|  _|    _|    _|_|_|  _|_|_|        //
//                                                       _|                //
//                                                   _|_|                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract strings is ERC721Creator {
    constructor() ERC721Creator(unicode"STRINGS :::..._I ••°|_...] _ [  editions ]", "strings") {}
}