// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FBA Anti Koon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                   __  .__ __                            //
//    _____    _____/  |_|__|  | ______   ____   ____      //
//    \__  \  /    \   __\  |  |/ /  _ \ /  _ \ /    \     //
//     / __ \|   |  \  | |  |    <  <_> |  <_> )   |  \    //
//    (____  /___|  /__| |__|__|_ \____/ \____/|___|  /    //
//         \/     \/             \/                 \/     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract Koon is ERC721Creator {
    constructor() ERC721Creator("FBA Anti Koon", "Koon") {}
}