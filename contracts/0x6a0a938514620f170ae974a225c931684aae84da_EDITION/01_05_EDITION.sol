// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GWENI Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//       _______          ________ _   _ _____     //
//      / ____\ \        / /  ____| \ | |_   _|    //
//     | |  __ \ \  /\  / /| |__  |  \| | | |      //
//     | | |_ | \ \/  \/ / |  __| | . ` | | |      //
//     | |__| |  \  /\  /  | |____| |\  |_| |_     //
//      \_____|   \/  \/   |______|_| \_|_____|    //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract EDITION is ERC721Creator {
    constructor() ERC721Creator("GWENI Editions", "EDITION") {}
}