// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INNA MODJA EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//     ___                        _   _                 //
//      |  |\ | |\ |  /\    |\/| / \ | \   |  /\        //
//     _|_ | \| | \| /--\   |  | \_/ |_/ \_| /--\       //
//      _  _  ___ ___ ___  _        __                  //
//     |_ | \  |   |   |  / \ |\ | (_                   //
//     |_ |_/ _|_  |  _|_ \_/ | \| __)                  //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract IME is ERC1155Creator {
    constructor() ERC1155Creator("INNA MODJA EDITIONS", "IME") {}
}