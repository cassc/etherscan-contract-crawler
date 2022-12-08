// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Angelic Official 4th Poster (Validated)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    The official contract of "Angelic: Daeva" NFT (Validated ver.),            //
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


contract ANGL4v is ERC1155Creator {
    constructor() ERC1155Creator("Angelic Official 4th Poster (Validated)", "ANGL4v") {}
}