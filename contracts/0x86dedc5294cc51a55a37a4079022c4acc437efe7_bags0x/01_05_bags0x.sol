// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xsecurebags
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    _______         ___.                             //
//    \   _  \ ___  __\_ |__ _____     ____  ______    //
//    /  /_\  \\  \/  /| __ \\__  \   / ___\/  ___/    //
//    \  \_/   \>    < | \_\ \/ __ \_/ /_/  >___ \     //
//     \_____  /__/\_ \|___  (____  /\___  /____  >    //
//           \/      \/    \/     \//_____/     \/     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract bags0x is ERC721Creator {
    constructor() ERC721Creator("0xsecurebags", "bags0x") {}
}