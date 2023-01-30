// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evolution
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//      ______          _       _   _                 //
//     |  ____|        | |     | | (_)                //
//     | |____   _____ | |_   _| |_ _  ___  _ __      //
//     |  __\ \ / / _ \| | | | | __| |/ _ \| '_ \     //
//     | |___\ V / (_) | | |_| | |_| | (_) | | | |    //
//     |______\_/ \___/|_|\__,_|\__|_|\___/|_| |_|    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract Evolution is ERC721Creator {
    constructor() ERC721Creator("Evolution", "Evolution") {}
}