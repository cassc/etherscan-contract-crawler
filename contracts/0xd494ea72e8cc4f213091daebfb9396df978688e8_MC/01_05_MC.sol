// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Multi Color by Manticore
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     _  _  __  __ _ ____ __ ___ __ ____ ____     //
//    ( \/ )/ _\(  ( (_  _(  / __/  (  _ (  __)    //
//    / \/ /    /    / )(  )( (_(  O )   /) _)     //
//    \_)(_\_/\_\_)__)(__)(__\___\__(__\_(____)    //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract MC is ERC721Creator {
    constructor() ERC721Creator("Multi Color by Manticore", "MC") {}
}