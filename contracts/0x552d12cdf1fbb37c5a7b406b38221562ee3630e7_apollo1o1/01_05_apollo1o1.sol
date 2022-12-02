// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apollo Fresh 1of1 songs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    ┏━━━┓╋╋╋╋╋┏┓┏┓╋╋╋╋┏━━━┓╋╋╋╋╋╋╋┏┓      //
//    ┃┏━┓┃╋╋╋╋╋┃┃┃┃╋╋╋╋┃┏━━┛╋╋╋╋╋╋╋┃┃      //
//    ┃┃╋┃┣━━┳━━┫┃┃┃┏━━┓┃┗━━┳━┳━━┳━━┫┗━┓    //
//    ┃┗━┛┃┏┓┃┏┓┃┃┃┃┃┏┓┃┃┏━━┫┏┫┃━┫━━┫┏┓┃    //
//    ┃┏━┓┃┗┛┃┗┛┃┗┫┗┫┗┛┃┃┃╋╋┃┃┃┃━╋━━┃┃┃┃    //
//    ┗┛╋┗┫┏━┻━━┻━┻━┻━━┛┗┛╋╋┗┛┗━━┻━━┻┛┗┛    //
//    ╋╋╋╋┃┃                                //
//    ╋╋╋╋┗┛                                //
//                                          //
//                                          //
//////////////////////////////////////////////


contract apollo1o1 is ERC721Creator {
    constructor() ERC721Creator("Apollo Fresh 1of1 songs", "apollo1o1") {}
}