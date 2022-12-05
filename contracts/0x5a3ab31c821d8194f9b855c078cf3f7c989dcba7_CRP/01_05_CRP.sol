// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cliche Roll Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//                          )      //
//     (    )   (        ( /(      //
//     )\  /((  )\   (   )\())     //
//    ((_)(_))\((_)  )\ ((_)\      //
//     (_)_)((_)(_) ((_)| |(_)     //
//     | |\ V / | |/ _| | ' \      //
//     |_| \_/  |_|\__| |_||_|     //
//                                 //
//                                 //
/////////////////////////////////////


contract CRP is ERC1155Creator {
    constructor() ERC1155Creator("Cliche Roll Pass", "CRP") {}
}