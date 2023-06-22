// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ResetNFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//      ____                _   _   _ _____ _____     //
//     |  _ \ ___  ___  ___| |_| \ | |  ___|_   _|    //
//     | |_) / _ \/ __|/ _ \ __|  \| | |_    | |      //
//     |  _ <  __/\__ \  __/ |_| |\  |  _|   | |      //
//     |_| \_\___||___/\___|\__|_| \_|_|     |_|      //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract RESETNFT is ERC1155Creator {
    constructor() ERC1155Creator("ResetNFT", "RESETNFT") {}
}