// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: umtksa
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                     _   _                  //
//                    | | | |                 //
//     _   _ _ __ ___ | |_| | _____  __ _     //
//    | | | | '_ ` _ \| __| |/ / __|/ _` |    //
//    | |_| | | | | | | |_|   <\__ \ (_| |    //
//     \__,_|_| |_| |_|\__|_|\_\___/\__,_|    //
//                                            //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract umtksa is ERC1155Creator {
    constructor() ERC1155Creator("umtksa", "umtksa") {}
}