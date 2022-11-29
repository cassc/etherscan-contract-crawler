// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Virgil Abloh Interview
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//     ____  __  ____    _  _  __  ____   ___  __  __       //
//    (  _ \(  )(  _ \  / )( \(  )(  _ \ / __)(  )(  )      //
//     )   / )(  ) __/  \ \/ / )(  )   /( (_ \ )( / (_/\    //
//    (__\_)(__)(__)     \__/ (__)(__\_) \___/(__)\____/    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract ABLOH is ERC721Creator {
    constructor() ERC721Creator("Virgil Abloh Interview", "ABLOH") {}
}