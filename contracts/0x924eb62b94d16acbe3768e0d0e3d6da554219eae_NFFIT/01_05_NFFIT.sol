// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Non-Fungible Fitness
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//                                                       //
//      _   _     _____   _____              _____       //
//     | \ |"|   |" ___| |" ___|    ___     |_ " _|      //
//    <|  \| |> U| |_  uU| |_  u   |_"_|      | |        //
//    U| |\  |u \|  _|/ \|  _|/     | |      /| |\       //
//     |_| \_|   |_|     |_|      U/| |\u   u |_|U       //
//     ||   \\,-.)(\\,-  )(\\,-.-,_|___|_,-._// \\_      //
//     (_")  (_/(__)(_/ (__)(_/ \_)-' '-(_/(__) (__)     //
//                                                       //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract NFFIT is ERC1155Creator {
    constructor() ERC1155Creator("Non-Fungible Fitness", "NFFIT") {}
}