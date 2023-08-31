// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ABSURD SPORTS | Wolfgang Biebach
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//        ___    ____ _____ __  ______  ____      //
//       /   |  / __ ) ___// / / / __ \/ __ \     //
//      / /| | / __  \__ \/ / / / /_/ / / / /     //
//     / ___ |/ /_/ /__/ / /_/ / _, _/ /_/ /      //
//    /_/__|_/_____/____/\____/_/_|_/_____/_      //
//      / ___// __ \/ __ \/ __ \/_  __/ ___/      //
//      \__ \/ /_/ / / / / /_/ / / /  \__ \       //
//     ___/ / ____/ /_/ / _, _/ / /  ___/ /       //
//    /____/_/    \____/_/ |_| /_/  /____/        //
//         _____________________________          //
//                                                //
//         BY 3D ARTIST WOLFGANG BIEBACH.         //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract ABSPO is ERC721Creator {
    constructor() ERC721Creator("ABSURD SPORTS | Wolfgang Biebach", "ABSPO") {}
}