// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avstn Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                _____              //
//               /     \             //
//              /       \            //
//        ,----<         >----.      //
//       /      \       /      \     //
//      /        \_____/        \    //
//      \        /     \        /    //
//       \      /       \      /     //
//        >----<         >----<      //
//       /      \       /      \     //
//      /        \_____/        \    //
//      \        /     \        /    //
//       \      /       \      /     //
//        `----<         >----'      //
//              \       /            //
//               \_____/             //
//                                   //
//                                   //
///////////////////////////////////////


contract AvstnEditions is ERC721Creator {
    constructor() ERC721Creator("Avstn Editions", "AvstnEditions") {}
}