// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by PretoHF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//      ____           _          _   _ _____     //
//     |  _ \ _ __ ___| |_ ___   | | | |  ___|    //
//     | |_) | '__/ _ \ __/ _ \  | |_| | |_       //
//     |  __/| | |  __/ || (_) | |  _  |  _|      //
//     |_|   |_|  \___|\__\___/  |_| |_|_|        //
//                                                //
//                                                //
//     Editions by PretoHF                        //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract PTOD is ERC1155Creator {
    constructor() ERC1155Creator("Editions by PretoHF", "PTOD") {}
}