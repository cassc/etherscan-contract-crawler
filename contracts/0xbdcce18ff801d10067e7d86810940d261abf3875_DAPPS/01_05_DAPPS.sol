// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EthereumDapps
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllc;,,,,,,,,,,,,,,,,,,:lc:,,:lllllllllllll    //
//    lllllllllllllllllllc,                   'cc.  .cllllllllllll    //
//    lllllllllllllllll;...                    ..   .cllllllllllll    //
//    llllllllllllll:;;.                            .,;;;;:cllllll    //
//    lllllllllllllc,                                     .cllllll    //
//    llllllllllc;...                                  .',;cllllll    //
//    llllllllllc,..                                   .clllllllll    //
//    lllllllllllccc'                      .'.         .clllllllll    //
//    lllllllllll;'..      ...   .......   .''...       ..,cllllll    //
//    llllllllllc,.       ....  ..'''',.   .'''''.        'cllllll    //
//    lllllllllllc::.   ...   ..'''''''.   .''''''...  .;:clllllll    //
//    llllllllllllll'   .'.........'''''....'''......  .clllllllll    //
//    lllllllllllcc:'  .''''''.......'''''''''......   .clllllllll    //
//    llllllllllc,.....''''''.   .''''''''''''.  ....  .clllllllll    //
//    llllllllllc'  .''''''''.....''''''''''''....''.  .clllllllll    //
//    llllllllllc'   .''''''''''''''''''''''''''''''.  .clllllllll    //
//    llllllllllc'     .',''''''''''''''''''''''''''.  .clllllllll    //
//    lllllllllll;..    .'''''''''''''''......''''''.  .clllllllll    //
//    lllllllllllllc'   ...''''''''''''..     .'''''.  .clllllllll    //
//    llllllllllllll'   ......''''''''''.......'''...  .clllllllll    //
//    llllllllllllll'   .......''''''''''''''''''...   .clllllllll    //
//    llllllllllllll'   ............................   .clllllllll    //
//    llllllllllllll'   ............................   .clllllllll    //
//    llllllllllllll'   ............................   .clllllllll    //
//    llllllllllllll'   .''.........................   .clllllllll    //
//    llllllllllllll'   .'''......................  .'';clllllllll    //
//    llllllllllllll'   .'''''....................  'cllllllllllll    //
//    llllllllllllll'   .'''''''.                .::clllllllllllll    //
//    llllllllllllll'   .'''''''.    ...........';llllllllllllllll    //
//    llllllllllllll'   .'''''''.   .;llllllllllllllllllllllllllll    //
//    llllllllllllll'   .'''''''.   .;llllllllllllllllllllllllllll    //
//    llllllllllllll;. .,;;;;;;;'. .':llllllllllllllllllllllllllll    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract DAPPS is ERC1155Creator {
    constructor() ERC1155Creator("EthereumDapps", "DAPPS") {}
}