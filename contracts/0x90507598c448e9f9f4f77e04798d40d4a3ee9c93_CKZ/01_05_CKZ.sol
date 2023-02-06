// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHECKZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     _____   _    ____ ___ ____     //
//    |__  /  / \  |  _ \_ _/ ___|    //
//      / /  / _ \ | | | | | |  _     //
//     / /_ / ___ \| |_| | | |_| |    //
//    /____/_/   \_\____/___\____|    //
//                                    //
//                                    //
////////////////////////////////////////


contract CKZ is ERC1155Creator {
    constructor() ERC1155Creator("CHECKZ", "CKZ") {}
}