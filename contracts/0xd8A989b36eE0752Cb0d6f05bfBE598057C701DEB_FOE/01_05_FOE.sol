// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freedom of Expression
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     ________ ________  _______          //
//    |\  _____\\   __  \|\  ___ \         //
//    \ \  \__/\ \  \|\  \ \   __/|        //
//     \ \   __\\ \  \\\  \ \  \_|/__      //
//      \ \  \_| \ \  \\\  \ \  \_|\ \     //
//       \ \__\   \ \_______\ \_______\    //
//        \|__|    \|_______|\|_______|    //
//                                         //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract FOE is ERC1155Creator {
    constructor() ERC1155Creator("Freedom of Expression", "FOE") {}
}