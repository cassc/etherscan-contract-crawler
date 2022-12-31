// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof Of Puff
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//                            //
//    ┏━┓╋╋╋╋┏━┳┓╋╋╋╋┏┓┏━┓    //
//    ┣━┣━┳━┳┫━┫┗┳━┳┳┫┗╋━┃    //
//    ┃━┫┻┫┃┃┣━┃┃┃╋┃┏┫┏┫━┫    //
//    ┗━┻━┻┻━┻━┻┻┻━┻┛┗━┻━┛    //
//                            //
//                            //
////////////////////////////////


contract POP is ERC1155Creator {
    constructor() ERC1155Creator("Proof Of Puff", "POP") {}
}