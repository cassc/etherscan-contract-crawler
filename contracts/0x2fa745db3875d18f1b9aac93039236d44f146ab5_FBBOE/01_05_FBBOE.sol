// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Filmbybcat Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//     ____   ____   __       __   ____   ____            //
//    /\  _`\/\  _`\/\ \     /\ \ /\  _`\/\  _`\          //
//    \ \,\L\_\ \ \/\ \ \____\ \ \\ \ \/\ \ \/\ \         //
//     \/_\__ \\ \ \ \ \ \_____\\ \_\\ \ \ \ \ \ \ \      //
//       /\ \L\ \ \ \_\ \/_____/ \/_/ \ \ \_\ \ \_\ \     //
//       \ `\____\ \____/\/_____/\/   \ \____/\ \____/    //
//        \/_____/\/___/\/_____/\/     \/___/  \/___/     //
//                    FILM BY BCAT                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract FBBOE is ERC1155Creator {
    constructor() ERC1155Creator("Filmbybcat Open Editions", "FBBOE") {}
}