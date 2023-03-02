// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstractnath
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ╭━━━┳╮╱╱╱╱╭╮╱╱╱╱╱╱╱╱╭╮╱╭━━━╮╱╭╮     //
//    ┃╭━╮┃┃╱╱╱╭╯╰╮╱╱╱╱╱╱╭╯╰╮┃╭━╮┃╭╯╰╮    //
//    ┃┃╱┃┃╰━┳━┻╮╭╋━┳━━┳━┻╮╭╯┃┃╱┃┣┻╮╭╯    //
//    ┃╰━╯┃╭╮┃━━┫┃┃╭┫╭╮┃╭━┫┃╱┃╰━╯┃╭┫┃     //
//    ┃╭━╮┃╰╯┣━━┃╰┫┃┃╭╮┃╰━┫╰╮┃╭━╮┃┃┃╰╮    //
//    ╰╯╱╰┻━━┻━━┻━┻╯╰╯╰┻━━┻━╯╰╯╱╰┻╯╰━╯    //
//                                        //
//                                        //
////////////////////////////////////////////


contract ABNATH is ERC721Creator {
    constructor() ERC721Creator("Abstractnath", "ABNATH") {}
}