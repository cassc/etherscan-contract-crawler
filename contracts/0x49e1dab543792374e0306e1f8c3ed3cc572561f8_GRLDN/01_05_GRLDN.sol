// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: geraldine-photo Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                         __   ___                   __        __         //
//      ___ ____ _______ _/ /__/ (_)__  ___ _______  / /  ___  / /____     //
//     / _ `/ -_) __/ _ `/ / _  / / _ \/ -_)___/ _ \/ _ \/ _ \/ __/ _ \    //
//     \_, /\__/_/  \_,_/_/\_,_/_/_//_/\__/   / .__/_//_/\___/\__/\___/    //
//    /___/                                  /_/                           //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract GRLDN is ERC1155Creator {
    constructor() ERC1155Creator("geraldine-photo Editions", "GRLDN") {}
}