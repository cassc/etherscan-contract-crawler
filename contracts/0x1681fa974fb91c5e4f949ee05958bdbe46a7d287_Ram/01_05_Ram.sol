// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AliRam
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      _____  .__  .____________                      //
//      /  _  \ |  | |__\______   \_____    _____      //
//     /  /_\  \|  | |  ||       _/\__  \  /     \     //
//    /    |    \  |_|  ||    |   \ / __ \|  Y Y  \    //
//    \____|__  /____/__||____|_  /(____  /__|_|  /    //
//            \/                \/      \/      \/     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Ram is ERC721Creator {
    constructor() ERC721Creator("AliRam", "Ram") {}
}