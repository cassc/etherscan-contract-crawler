// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AndyShaw.xyz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//       _|_|    _|      _|  _|_|_|    _|      _|      //
//     _|    _|  _|_|    _|  _|    _|    _|  _|        //
//     _|_|_|_|  _|  _|  _|  _|    _|      _|          //
//     _|    _|  _|    _|_|  _|    _|      _|          //
//     _|    _|  _|      _|  _|_|_|        _|          //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract ASXYZ is ERC721Creator {
    constructor() ERC721Creator("AndyShaw.xyz", "ASXYZ") {}
}