// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Axstone
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//       _  __  ____  _____  ___    __  __     //
//      /_\ \ \/ / _\/__   \/___\/\ \ \/__\    //
//     //_\\ \  /\ \   / /\//  //  \/ /_\      //
//    /  _  \/  \_\ \ / / / \_// /\  //__      //
//    \_/ \_/_/\_\__/ \/  \___/\_\ \/\__/      //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract Axstone is ERC1155Creator {
    constructor() ERC1155Creator("Axstone", "Axstone") {}
}