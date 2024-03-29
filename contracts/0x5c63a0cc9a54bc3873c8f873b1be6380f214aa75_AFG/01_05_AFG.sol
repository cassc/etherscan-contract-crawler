// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AfterGlow
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//                                                                                             //
//          _____         _____         _____          _____         _____        _____        //
//     ___|\     \   ___|\     \    ___|\    \     ___|\    \   ____|\    \   ___|\    \       //
//    |    |\     \ |    |\     \  /    /\    \   /    /\    \ |    | \    \ /    /\    \      //
//    |    | |     ||    | |     ||    |  |____| |    |  |    ||    |______/|    |  |____|     //
//    |    | /_ _ / |    | /_ _ / |    |    ____ |    |__|    ||    |----'\ |    |    ____     //
//    |    |\    \  |    |\    \  |    |   |    ||    .--.    ||    |_____/ |    |   |    |    //
//    |    | |    | |    | |    | |    |   |_,  ||    |  |    ||    |       |    |   |_,  |    //
//    |____|/____/| |____|/____/| |\ ___\___/  /||____|  |____||____|       |\ ___\___/  /|    //
//    |    /     || |    /     || | |   /____ / ||    |  |    ||    |       | |   /____ / |    //
//    |____|_____|/ |____|_____|/  \|___|    | / |____|  |____||____|        \|___|    | /     //
//      \(    )/      \(    )/       \( |____|/    \(      )/    )/            \( |____|/      //
//       '    '        '    '         '   )/        '      '     '              '   )/         //
//                                        '                                         '          //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract AFG is ERC721Creator {
    constructor() ERC721Creator("AfterGlow", "AFG") {}
}