// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Akashi30eth x Mpozzecco Collab
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                  _..._           //
//                                 .-'_..._''.      //
//              __  __   ___     .' .'      '.\     //
//             |  |/  `.'   `.  / .'                //
//             |   .-.  .-.   '. '                  //
//        __   |  |  |  |  |  || |                  //
//     .:--.'. |  |  |  |  |  || |                  //
//    / |   \ ||  |  |  |  |  |. '                  //
//    `" __ | ||  |  |  |  |  | \ '.          .     //
//     .'.''| ||__|  |__|  |__|  '. `._____.-'/     //
//    / /   | |_                   `-.______ /      //
//    \ \._,\ '/                            `       //
//     `--'  `"                                     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract AMC is ERC1155Creator {
    constructor() ERC1155Creator("Akashi30eth x Mpozzecco Collab", "AMC") {}
}