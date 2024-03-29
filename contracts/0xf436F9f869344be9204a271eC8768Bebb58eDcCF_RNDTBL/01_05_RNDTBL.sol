// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CYBR RNDTBL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//     __________________________________________________________________    //
//    /_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/    //
//      / ____/\ \/ / __ )/ __ \   / __ \/ | / / __ \/_  __/ __ )/ /         //
//     / /      \  / __  / /_/ /  / /_/ /  |/ / / / / / / / __  / /          //
//    / /___    / / /_/ / _, _/  / _, _/ /|  / /_/ / / / / /_/ / /___        //
//    \____/___/_/_____/_/_|_|__/_/_|_/_/_|_/_____/_/_/_/_____/_____/        //
//    /_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/          //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract RNDTBL is ERC721Creator {
    constructor() ERC721Creator("CYBR RNDTBL", "RNDTBL") {}
}