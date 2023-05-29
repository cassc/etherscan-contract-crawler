// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Back in Time
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      ___          _     _        _____ _               //
//     | _ ) __ _ __| |__ (_)_ _   |_   _(_)_ __  ___     //
//     | _ \/ _` / _| / / | | ' \    | | | | '  \/ -_)    //
//     |___/\__,_\__|_\_\ |_|_||_|   |_| |_|_|_|_\___|    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract BIT is ERC721Creator {
    constructor() ERC721Creator("Back in Time", "BIT") {}
}