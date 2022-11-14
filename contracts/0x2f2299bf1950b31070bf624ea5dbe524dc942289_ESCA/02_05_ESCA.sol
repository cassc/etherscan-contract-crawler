// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ESCA-NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ┏━━┓┏━━┓┏━━┓┏━━┓       //
//    ┃┏━┛┃┏━┛┃┏━┛┃┏┓┃       //
//    ┃┗━┓┃┗━┓┃┃　 /＊┃ ┗┛┃    //
//    ┃┏━┛┗━┓┃┃┃　 /＊┃ ┏┓┃    //
//    ┃┗━┓┏━┛┃┃┗━┓┃┃ ┃┃      //
//    ┗━━┛┗━━┛┗━━┛┗┛ ┗┛      //
//                           //
//                           //
///////////////////////////////


contract ESCA is ERC721Creator {
    constructor() ERC721Creator("ESCA-NFT", "ESCA") {}
}