// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seattle Skies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                _         _                    //
//      __   ___.--'_`.     .'_`--.___   __      //
//     ( _`.'. -   'o` )   ( 'o`   - .`.'_ )     //
//     _\.'_'      _.-'     `-._      `_`./_     //
//    ( \`. )    //\`         '/\\    ( .'/ )    //
//     \_`-'`---'\\__,       ,__//`---'`-'_/     //
//      \`        `-\         /-'        '/      //
//       `                               '       //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract KAYTO is ERC721Creator {
    constructor() ERC721Creator("Seattle Skies", "KAYTO") {}
}