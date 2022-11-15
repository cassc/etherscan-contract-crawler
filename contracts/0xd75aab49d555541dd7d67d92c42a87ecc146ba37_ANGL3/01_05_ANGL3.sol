// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Angelic Official Poster
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    The official contract of "Angelic: Daeva" free NFT,                        //
//    part of the "Angels of Chaos" series, by Metaverse Game Studios.           //
//                                                                               //
//     █████╗ ███╗   ██╗ ██████╗ ███████╗██╗     ██╗ ██████╗                     //
//    ██╔══██╗████╗  ██║██╔════╝ ██╔════╝██║     ██║██╔════╝                     //
//    ███████║██╔██╗ ██║██║  ███╗█████╗  ██║     ██║██║                          //
//    ██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██║     ██║██║                          //
//    ██║  ██║██║ ╚████║╚██████╔╝███████╗███████╗██║╚██████╗                     //
//    ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝ ╚═════╝                     //
//                                                                               //
//    (C) Metaverse Studios FZCO & Affiliates 2020-2022. All rights reserved.    //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract ANGL3 is ERC721Creator {
    constructor() ERC721Creator("Angelic Official Poster", "ANGL3") {}
}