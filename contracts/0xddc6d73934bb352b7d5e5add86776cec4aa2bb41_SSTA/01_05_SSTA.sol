// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Standing Skeleton Tree Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//      __              __             ____         _          //
//     ( _/_   _/'  _  (  / _ /_ _/     /  _ _ _   /_| __/     //
//    __)/(//)(///)(/ __)/((-((- /()/) (  / (-(-  (  |/ /      //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract SSTA is ERC721Creator {
    constructor() ERC721Creator("Standing Skeleton Tree Art", "SSTA") {}
}