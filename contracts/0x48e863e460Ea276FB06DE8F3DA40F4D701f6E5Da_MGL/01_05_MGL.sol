// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Material Girl
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//       __  ___     __          _      __  ______     __    //
//      /  |/  /__ _/ /____ ____(_)__ _/ / / ___(_)___/ /    //
//     / /|_/ / _ `/ __/ -_) __/ / _ `/ / / (_ / / __/ /     //
//    /_/  /_/\_,_/\__/\__/_/ /_/\_,_/_/  \___/_/_/ /_/      //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract MGL is ERC1155Creator {
    constructor() ERC1155Creator("Material Girl", "MGL") {}
}