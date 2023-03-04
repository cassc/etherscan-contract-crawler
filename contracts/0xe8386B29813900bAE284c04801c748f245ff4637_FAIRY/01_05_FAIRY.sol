// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fairy Prizes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//       █████▒▄▄▄       ██▓ ██▀███ ▓██   ██▓    //
//    ▓██   ▒▒████▄    ▓██▒▓██ ▒ ██▒▒██  ██▒     //
//    ▒████ ░▒██  ▀█▄  ▒██▒▓██ ░▄█ ▒ ▒██ ██░     //
//    ░▓█▒  ░░██▄▄▄▄██ ░██░▒██▀▀█▄   ░ ▐██▓░     //
//    ░▒█░    ▓█   ▓██▒░██░░██▓ ▒██▒ ░ ██▒▓░     //
//     ▒ ░    ▒▒   ▓▒█░░▓  ░ ▒▓ ░▒▓░  ██▒▒▒      //
//     ░       ▒   ▒▒ ░ ▒ ░  ░▒ ░ ▒░▓██ ░▒░      //
//     ░ ░     ░   ▒    ▒ ░  ░░   ░ ▒ ▒ ░░       //
//                 ░  ░ ░     ░     ░ ░          //
//                                  ░ ░          //
//               Rugproof Raffles.               //
//       Fair, verifiable, fully on-chain.       //
//               https://fairy.win               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract FAIRY is ERC1155Creator {
    constructor() ERC1155Creator("Fairy Prizes", "FAIRY") {}
}