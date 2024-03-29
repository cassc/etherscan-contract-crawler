// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Louie C Rhymes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//     ____   _____  __ __  ___  _____     _____     _____  __ __ ___ ___ __  __  _____  _____     //
//    /  _/  /  _  \/  |  \/___\/   __\   /     \   /  _  \/  |  \\  |  //  \/  \/   __\/  ___>    //
//    |  |---|  |  ||  |  ||   ||   __|   |  |--|   |  _  <|  _  | |   | |  \/  ||   __||___  |    //
//    \_____/\_____/\_____/\___/\_____/   \_____/   \__|\_/\__|__/ \___/ \__ \__/\_____/<_____/    //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract LCR is ERC721Creator {
    constructor() ERC721Creator("Louie C Rhymes", "LCR") {}
}