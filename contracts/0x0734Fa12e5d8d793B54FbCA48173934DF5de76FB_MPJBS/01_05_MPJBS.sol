// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Machu Picchu by JayBomSenhor
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    _______         __________._____________    //
//    \   _  \ ___  __\______   \__\_   _____/    //
//    /  /_\  \\  \/  /|     ___/  ||    __)      //
//    \  \_/   \>    < |    |   |  ||     \       //
//     \_____  /__/\_ \|____|   |__|\___  /       //
//           \/      \/                 \/        //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract MPJBS is ERC721Creator {
    constructor() ERC721Creator("Machu Picchu by JayBomSenhor", "MPJBS") {}
}