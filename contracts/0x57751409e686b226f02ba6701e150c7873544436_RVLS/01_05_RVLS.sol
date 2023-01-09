// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rvlsky
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//         _        _        _        _        //
//       _( )__   _( )__   _( )__   _( )__     //
//     _|     _|_|     _|_|     _|_|     _|    //
//    (_ R _ (_(_ V _ (_(_ L _ (_(_ S _ (_     //
//      |_( )__| |_( )__| |_( )__| |_( )__|    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract RVLS is ERC1155Creator {
    constructor() ERC1155Creator("rvlsky", "RVLS") {}
}