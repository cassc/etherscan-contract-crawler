// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: e•a•t•}works Membership Token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                 _                      _             //
//       ___  __ _| |___      _____  _ __| | _____      //
//      / _ \/ _` | __\ \ /\ / / _ \| '__| |/ / __|     //
//     |  __/ (_| | |_ \ V  V / (_) | |  |   <\__ \     //
//      \___|\__,_|\__| \_/\_/ \___/|_|  |_|\_\___/     //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract EAT is ERC721Creator {
    constructor() ERC721Creator(unicode"e•a•t•}works Membership Token", "EAT") {}
}