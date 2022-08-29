// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Confined by Stars
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//     __  __  _____   ______ __    __                                    //
//    /\ \/\ \/\  __`\/\__  _/\ \  /\ \                                   //
//    \ \ `\\ \ \ \/\ \/_/\ \\ `\`\\/'/                                   //
//     \ \ , ` \ \ \ \ \ \ \ \`\ `\ /'                                    //
//      \ \ \`\ \ \ \_\ \ \ \ \ `\ \ \                                    //
//       \ \_\ \_\ \_____\ \ \_\  \ \_\                                   //
//        \/_/\/_/\/_____/  \/_/   \/_/                                   //
//                                                                        //
//    By interacting with this smart contract, you agree to the terms     //
//    located at https://www.nightontheyard.com/legal/terms-of-service    //
//    and https://www.nightontheyard.com/legal/privacy-policy             //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract NOTY is ERC721Creator {
    constructor() ERC721Creator("Confined by Stars", "NOTY") {}
}