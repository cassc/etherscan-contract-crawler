// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sara Nmt Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//       _____                     _   __          __     //
//      / ___/____ __________ _   / | / /___ ___  / /_    //
//      \__ \/ __ `/ ___/ __ `/  /  |/ / __ `__ \/ __/    //
//     ___/ / /_/ / /  / /_/ /  / /|  / / / / / / /_      //
//    /____/\__,_/_/   \__,_/  /_/ |_/_/ /_/ /_/\__/      //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract SNE is ERC1155Creator {
    constructor() ERC1155Creator("Sara Nmt Editions", "SNE") {}
}