// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FlighCo Claim Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     ______   __         __     ______     __  __        //
//    /\  ___\ /\ \       /\ \   /\  ___\   /\ \_\ \       //
//    \ \  __\ \ \ \____  \ \ \  \ \ \__ \  \ \  __ \      //
//     \ \_\    \ \_____\  \ \_\  \ \_____\  \ \_\ \_\     //
//      \/_/     \/_____/   \/_/   \/_____/   \/_/\/_/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract FlighCo is ERC1155Creator {
    constructor() ERC1155Creator("FlighCo Claim Collection", "FlighCo") {}
}