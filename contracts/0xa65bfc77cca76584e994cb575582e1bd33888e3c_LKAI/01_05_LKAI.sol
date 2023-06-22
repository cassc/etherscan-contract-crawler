// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Linda Kristiansen - AI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//       _       _  __      _                      //
//      |"|     |"|/ /  U  /"\  u     ___          //
//    U | | u   | ' /    \/ _ \/     |_"_|         //
//     \| |/__U/| . \\u  / ___ \      | |          //
//      |_____| |_|\_\  /_/   \_\   U/| |\u        //
//      //  \\,-,>> \\,-.\\    >>.-,_|___|_,-.     //
//     (_")("_)\.)   (_/(__)  (__)\_)-' '-(_/      //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract LKAI is ERC721Creator {
    constructor() ERC721Creator("Linda Kristiansen - AI", "LKAI") {}
}