// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Sands
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//       ___           __    ____             __      //
//      / _ \___ _____/ /__ / __/__ ____  ___/ /__    //
//     / // / _ `/ __/  '_/_\ \/ _ `/ _ \/ _  (_-<    //
//    /____/\_,_/_/ /_/\_\/___/\_,_/_//_/\_,_/___/    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract DRKSNDS is ERC721Creator {
    constructor() ERC721Creator("Dark Sands", "DRKSNDS") {}
}