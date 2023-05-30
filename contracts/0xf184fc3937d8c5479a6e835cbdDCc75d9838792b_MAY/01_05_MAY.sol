// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MayNakasaki
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      __  __      __     __    //
//     |  \/  |   /\\ \   / /    //
//     | \  / |  /  \\ \_/ /     //
//     | |\/| | / /\ \\   /      //
//     | |  | |/ ____ \| |       //
//     |_|  |_/_/    \_\_|       //
//                               //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract MAY is ERC1155Creator {
    constructor() ERC1155Creator("MayNakasaki", "MAY") {}
}