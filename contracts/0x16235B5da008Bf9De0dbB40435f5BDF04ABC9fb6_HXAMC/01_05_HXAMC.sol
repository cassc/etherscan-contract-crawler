// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hieroglyphica x Ana María Caballero
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//             ┬ ┬┬┌─┐┬─┐┌─┐┌─┐┬ ┬ ┬┌─┐┬ ┬┬┌─┐┌─┐                //
//             ├─┤│├┤ ├┬┘│ ││ ┬│ └┬┘├─┘├─┤││  ├─┤                //
//             ┴ ┴┴└─┘┴└─└─┘└─┘┴─┘┴ ┴  ┴ ┴┴└─┘┴ ┴                //
//                            ─┐ ┬                               //
//                            ┌┴┬┘                               //
//                            ┴ └─                               //
//    ╔═╗┌┐┌┌─┐  ╔╦╗┌─┐┬─┐┬┌─┐  ╔═╗┌─┐┌┐ ┌─┐┬  ┬  ┌─┐┬─┐┌─┐      //
//    ╠═╣│││├─┤  ║║║├─┤├┬┘│├─┤  ║  ├─┤├┴┐├─┤│  │  ├┤ ├┬┘│ │      //
//    ╩ ╩┘└┘┴ ┴  ╩ ╩┴ ┴┴└─┴┴ ┴  ╚═╝┴ ┴└─┘┴ ┴┴─┘┴─┘└─┘┴└─└─┘      //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract HXAMC is ERC721Creator {
    constructor() ERC721Creator(unicode"hieroglyphica x Ana María Caballero", "HXAMC") {}
}