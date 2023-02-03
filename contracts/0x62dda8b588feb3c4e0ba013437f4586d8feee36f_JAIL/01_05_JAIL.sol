// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STRAIGHTOJAIL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    .-.   .-..----.---. .--. .-. .-.----..----.  .----.----.                        //
//    |  `.'  || {_{_   _} {} \| | | | {_  | {}  }{ {__ | {_                          //
//    | |\ /| || {__ | |/  /\  \ \_/ / {__ | .-. \.-._} } {__                         //
//    `-' ` `-'`----'`-'`-'  `-'`---'`----'`-' `-'`----'`----'                        //
//       .-.  .--.  .-..-.                                                            //
//    .-.| | / {} \ | || |                                                            //
//    | {} |/  /\  \| || `--.                                                         //
//    `----'`-'  `-'`-'`----'                                                         //
//                                                                                    //
//    A fun meme card for use sending influencoooors, scamoooors, and griftoooorrs    //
//    straight to jail!                                                               //
//                                                                                    //
//    Holding one Straight to Jail card makes you an deputy of the PunksPolice        //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract JAIL is ERC1155Creator {
    constructor() ERC1155Creator("STRAIGHTOJAIL", "JAIL") {}
}