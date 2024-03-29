// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: family
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//     ______   ______     __    __     __     __         __  __        //
//    /\  ___\ /\  __ \   /\ "-./  \   /\ \   /\ \       /\ \_\ \       //
//    \ \  __\ \ \  __ \  \ \ \-./\ \  \ \ \  \ \ \____  \ \____ \      //
//     \ \_\    \ \_\ \_\  \ \_\ \ \_\  \ \_\  \ \_____\  \/\_____\     //
//      \/_/     \/_/\/_/   \/_/  \/_/   \/_/   \/_____/   \/_____/     //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract FM is ERC1155Creator {
    constructor() ERC1155Creator() {}
}