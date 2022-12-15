// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yura Kimakovych
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Limited Edition     //
//    Yura Kimakovych     //
//    2022                //
//                        //
//                        //
////////////////////////////


contract YK is ERC721Creator {
    constructor() ERC721Creator("Yura Kimakovych", "YK") {}
}