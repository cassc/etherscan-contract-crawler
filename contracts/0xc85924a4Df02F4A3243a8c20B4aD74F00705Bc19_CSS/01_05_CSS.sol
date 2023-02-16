// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Comp Stomp Studios
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,:dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:,,,,    //
//    ,,,,lXMMWNNNNWWMMMMMWWNNNNNNNNNNNNNNNNWWMMMMMWWNNNNWMMXl,,,,    //
//    ,,,,lXMWkcccckNMMMMMXdccccccccccccccccdXMMMMMWkcccckWMXl,,,,    //
//    ,,,,lXMWx,,,lXMMMMMMM0c,,,,,,,,,,,,,,c0WMMMMMMXo,,,dWMXl,,,,    //
//    ,,,,lXMWx,,lXMMMMMMMMM0c,,,,,,,,,,,,:0WMMMMMMMMXl,,dWMXl,,,,    //
//    ,,,,lXMWx,lKMMMMMMMMMMW0:,,,,,,,,,,:OWMMMMMMMMMMXl,dWMXl,,,,    //
//    ,,,,lXMWxlKMMMMMMMMMMMMWO:,,,,,,,,:OWMMMMMMMMMMMMKldWMXl,,,,    //
//    ,,,,lXMW0KMMMMMMMMMMMMMMWO:,,,,,,:OWMMMMMMMMMMMMMMK0WMXl,,,,    //
//    ,,,,lXMMMMMMMMMMMMMMMMMMMWO:,,,,:kWMMMMMMMMMMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMMMMMMMMMMMMWO:,,:kWMMMMMMMMMMMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMMMMMMMMMMMMMWkcckWMMMMMMMMMMMMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMMWOdKMMMMMMMMMMMMMMMMMMMMMMKdOWMMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMMW0:,lXMMMMMMMMMMMMMMMMMMMMXl,:0WMMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMMW0c,,,oXMMMMMMMMMMMMMMMMMMXo,,,c0WMMMMMMMXl,,,,    //
//    ,,,,lXMMMMMMM0c,,,,,oXMMMMMMMMMMMMMMMMXo,,,,,c0MMMMMMMXl,,,,    //
//    ,,,,lXMMMMMM0c,,,,,,,oXMMMMMMMMMMMMMMXo,,,,,,,c0MMMMMMXl,,,,    //
//    ,,,,lXMMMMMKc,,,,,,,,,oXMMMMMMMMMMMMXo,,,,,,,,,cKMMMMMXl,,,,    //
//    ,,,,lXMMMMKc,,,,,,,,,,,dNMMMMMMMMMMNd,,,,,,,,,,,cKMMMMXl,,,,    //
//    ,,,,lXMMMKl,,,,,,,,,,,,,dNMMMMMMMMNd,,,,,,,,,,,,,lKMMMXl,,,,    //
//    ,,,,lXMMXl,,,,,,,,,,,,,,;xNMMMMMMNx;,,,,,,,,,,,,,,lXMMXl,,,,    //
//    ,,,,lXMMN0000000000000000KNMMMMMMNK0000000000000000NMMXc,,,,    //
//    ,,,,c0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0c,,,,    //
//    ,,,,,::::::::::::::::::::::::::::::::::::::::::::::::::,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract CSS is ERC721Creator {
    constructor() ERC721Creator("Comp Stomp Studios", "CSS") {}
}