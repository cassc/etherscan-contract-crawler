// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seize for Charity
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     __ __ ___ __   __ __  __    __         __  ___        //
//    (_ |_ | _/|_   |_ /  \|__)  /  |__| /\ |__)| | \_/     //
//    __)|__|/__|__  |  \__/| \   \__|  |/--\| \ | |  |      //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract SFC is ERC1155Creator {
    constructor() ERC1155Creator("Seize for Charity", "SFC") {}
}