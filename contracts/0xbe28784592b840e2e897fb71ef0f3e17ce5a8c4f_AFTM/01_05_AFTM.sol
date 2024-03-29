// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aftermath
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                __ _                            _   _         //
//         /\    / _| |                          | | | |        //
//        /  \  | |_| |_ ___ _ __ _ __ ___   __ _| |_| |__      //
//       / /\ \ |  _| __/ _ \ '__| '_ ` _ \ / _` | __| '_ \     //
//      / ____ \| | | ||  __/ |  | | | | | | (_| | |_| | | |    //
//     /_/    \_\_|  \__\___|_|  |_| |_| |_|\__,_|\__|_| |_|    //
//                                                              //
//     __                                                       //
//    |  \  |\/| _  _  _  _                                     //
//    |__/  |  |(_|| )| )_)                                     //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract AFTM is ERC721Creator {
    constructor() ERC721Creator("Aftermath", "AFTM") {}
}