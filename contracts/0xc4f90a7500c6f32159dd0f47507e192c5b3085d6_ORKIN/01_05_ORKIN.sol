// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Orkin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//    ________ __________ ____  __.___ _______       //
//    \_____  \\______   \    |/ _|   |\      \      //
//     /   |   \|       _/      < |   |/   |   \     //
//    /    |    \    |   \    |  \|   /    |    \    //
//    \_______  /____|_  /____|__ \___\____|__  /    //
//            \/       \/        \/           \/     //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract ORKIN is ERC1155Creator {
    constructor() ERC1155Creator("Orkin", "ORKIN") {}
}