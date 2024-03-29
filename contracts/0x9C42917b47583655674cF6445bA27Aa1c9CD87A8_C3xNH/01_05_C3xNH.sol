// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: C3 x New Here
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    C3                                                                               //
//     _______ _    _ ______   _____  _____  ______          __  __ ______ _____       //
//     |__   __| |  | |  ____| |  __ \|  __ \|  ____|   /\   |  \/  |  ____|  __ \     //
//        | |  | |__| | |__    | |  | | |__) | |__     /  \  | \  / | |__  | |__) |    //
//        | |  |  __  |  __|   | |  | |  _  /|  __|   / /\ \ | |\/| |  __| |  _  /     //
//        | |  | |  | | |____  | |__| | | \ \| |____ / ____ \| |  | | |____| | \ \     //
//        |_|  |_|  |_|______| |_____/|_|  \_\______/_/    \_\_|  |_|______|_|  \_\    //
//                                                                                     //
//                                                                         NEW HERE    //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract C3xNH is ERC1155Creator {
    constructor() ERC1155Creator("C3 x New Here", "C3xNH") {}
}