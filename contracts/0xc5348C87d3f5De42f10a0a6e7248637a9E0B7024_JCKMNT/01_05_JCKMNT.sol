// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jack Mint
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//           _            _      __  __ _       _       //
//          | |          | |    |  \/  (_)     | |      //
//          | | __ _  ___| | __ | \  / |_ _ __ | |_     //
//      _   | |/ _` |/ __| |/ / | |\/| | | '_ \| __|    //
//     | |__| | (_| | (__|   <  | |  | | | | | | |_     //
//      \____/ \__,_|\___|_|\_\ |_|  |_|_|_| |_|\__|    //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract JCKMNT is ERC1155Creator {
    constructor() ERC1155Creator("Jack Mint", "JCKMNT") {}
}