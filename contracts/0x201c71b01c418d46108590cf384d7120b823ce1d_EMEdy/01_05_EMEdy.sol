// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mboo Eboo Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    _._     _,-'""`-._                                       //
//    (,-.`._,'(       |\`-/|                                  //
//        `-.-' \ )-`( , o o)                                  //
//              `-    \`_`"'-                |\__/,|   (`\     //
//                                           |_ _  |.--.) )    //
//                                           ( T   )     /     //
//                                          (((^_(((/(((_/     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract EMEdy is ERC1155Creator {
    constructor() ERC1155Creator("Mboo Eboo Editions", "EMEdy") {}
}