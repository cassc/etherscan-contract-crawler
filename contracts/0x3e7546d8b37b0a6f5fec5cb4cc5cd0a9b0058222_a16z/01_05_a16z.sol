// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a16z
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//           __    ____         //
//          /  |  / ___|        //
//      __ _`| | / /___ ____    //
//     / _` || | | ___ \_  /    //
//    | (_| || |_| \_/ |/ /     //
//     \__,_\___/\_____/___|    //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract a16z is ERC721Creator {
    constructor() ERC721Creator("a16z", "a16z") {}
}