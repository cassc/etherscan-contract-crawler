// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LINEA-HUMANITY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                    _                                   _      //
//       ___ ___   __| | ___   _ __      _____   ___   __| |     //
//      / __/ _ \ / _` |/ _ \_| |\ \ /\ / / _ \ / _ \ / _` |     //
//     | (_| (_) | (_| |  __/_   _\ V  V / (_) | (_) | (_| |     //
//      \___\___/ \__,_|\___| |_|  \_/\_/ \___/ \___/ \__,_|     //
//    -------------------------------------- Matthijs Keuper     //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract CWLH is ERC721Creator {
    constructor() ERC721Creator("LINEA-HUMANITY", "CWLH") {}
}