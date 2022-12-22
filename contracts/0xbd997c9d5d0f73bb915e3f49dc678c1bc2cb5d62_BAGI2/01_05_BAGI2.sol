// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAGIRA EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//     ____          _____ _____ _____                //
//    |  _ \   /\   / ____|_   _|  __ \     /\        //
//    | |_) | /  \ | |  __  | | | |__) |   /  \       //
//    |  _ < / /\ \| | |_ | | | |  _  /   / /\ \      //
//    | |_) / ____ \ |__| |_| |_| | \ \  / ____ \     //
//    |____/_/    \_\_____|_____|_|  \_\/_/    \_\    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract BAGI2 is ERC1155Creator {
    constructor() ERC1155Creator("BAGIRA EDITIONS", "BAGI2") {}
}