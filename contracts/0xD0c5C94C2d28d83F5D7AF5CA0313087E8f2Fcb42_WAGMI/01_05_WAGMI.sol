// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WAGMI Music Red Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ▄▄▌ ▐ ▄▌ ▄▄▄·  ▄▄ • • ▌ ▄ ·. ▪      //
//    ██· █▌▐█▐█ ▀█ ▐█ ▀ ▪·██ ▐███▪██     //
//    ██▪▐█▐▐▌▄█▀▀█ ▄█ ▀█▄▐█ ▌▐▌▐█·▐█·    //
//    ▐█▌██▐█▌▐█ ▪▐▌▐█▄▪▐███ ██▌▐█▌▐█▌    //
//     ▀▀▀▀ ▀▪ ▀  ▀ ·▀▀▀▀ ▀▀  █▪▀▀▀▀▀▀    //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract WAGMI is ERC1155Creator {
    constructor() ERC1155Creator("WAGMI Music Red Edition", "WAGMI") {}
}