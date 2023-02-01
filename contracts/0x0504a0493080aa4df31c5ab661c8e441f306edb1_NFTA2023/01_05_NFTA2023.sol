// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFT Awards 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//     __________       //
//    '._==_==_=_.'     //
//    .-\:      /-.     //
//     (|:.     |) |    //
//    '-|:.     |-'     //
//      \::.    /       //
//       '::. .'        //
//         ) (          //
//       _.' '._        //
//      `"""""""`       //
//                      //
//                      //
//////////////////////////


contract NFTA2023 is ERC1155Creator {
    constructor() ERC1155Creator("NFT Awards 2023", "NFTA2023") {}
}