// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Escaparates de Verano
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//          /))   _   _________________       ((\      //
//         / / _ / ` |               ,^|  ,- _ \ \     //
//        / / / / /`_| escaparates de  |,-\ \ \ \ \    //
//        | |/ / / / |    verano       | \ \ \ \| |    //
//        | / / / / /|arte indigo 2023 |\ \ \ \ \ |    //
//        | | | `'  (|/(|___________|)\|    ' | | |    //
//        |          `\  \         /  /,          |    //
//        \           |  |         |  |          /     //
//         \             |         |            /      //
//          \           /          \           /       //
//           \         /            \         /        //
//            \       /              )       /         //
//            )      /              /       /          //
//           /                     /       /           //
//                                /                    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract EV2023 is ERC721Creator {
    constructor() ERC721Creator("Escaparates de Verano", "EV2023") {}
}