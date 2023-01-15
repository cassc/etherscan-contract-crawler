// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tazzista.eth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    _____   __   ____ ____  _   __  _____   __       //
//     | |   / /\   / /  / / | | ( (`  | |   / /\      //
//     |_|  /_/--\ /_/_ /_/_ |_| _)_)  |_|  /_/--\     //
//                  __    ___  _____                   //
//                 / /\  | |_)  | |                    //
//                /_/--\ |_| \  |_|                    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Tazz is ERC721Creator {
    constructor() ERC721Creator("tazzista.eth", "Tazz") {}
}