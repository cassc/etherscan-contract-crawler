// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SatiDrawsEditions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      ____        _   _ ____                             //
//     / ___|  __ _| |_(_)  _ \ _ __ __ ___      _____     //
//     \___ \ / _` | __| | | | | '__/ _` \ \ /\ / / __|    //
//      ___) | (_| | |_| | |_| | | | (_| |\ V  V /\__ \    //
//     |____/ \__,_|\__|_|____/|_|  \__,_| \_/\_/ |___/    //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract SDE is ERC1155Creator {
    constructor() ERC1155Creator("SatiDrawsEditions", "SDE") {}
}