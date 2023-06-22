// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Downs & Towns - Advocacy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//     ______       __     _________    //
//    (  __  \     /__\    \__   __/    //
//    | (  \  )   ( \/ )      ) (       //
//    | |   ) |    \  /       | |       //
//    | |   | |    /  \/\     | |       //
//    | |   ) |   / /\  /     | |       //
//    | (__/  )  (  \/  \     | |       //
//    (______/    \___/\/     )_(       //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract ADVC8 is ERC1155Creator {
    constructor() ERC1155Creator("Downs & Towns - Advocacy", "ADVC8") {}
}