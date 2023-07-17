// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ribbits & Co. Club 6969 Silver Ed.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ```                                                                                                     //
//    888888ba  oo dP       dP       oo   dP                  d88b        a88888b.                            //
//    88    `8b    88       88            88   .d8888b.      d8  88      d8'   `88                            //
//    a88aaaa8P'dP 88d888b. 88d888b. dP d8888P 88             d8b        88        .d8888b.                   //
//    88   `8b. 88 88'  `88 88'  `88 88   88   Y8ooooo.     d8P`8b       88        88'  `88        θ)__       //
//    88     88 88 88.  .88 88.  .88 88   88         88     d8' `8bP     Y8.   .88 88.  .88       (_  _`\     //
//    dP     dP dP 88Y8888' 88Y8888' dP   dP   `88888P'     `888P'`YP     Y88888P' `88888P' 88     z/z\__)    //
//                                                                                                            //
//                                           ________________________                                         //
//                                          | Dream / Leap / Succeed |                                        //
//                                           ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾                                         //
//    ```                                                                                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RBECS is ERC1155Creator {
    constructor() ERC1155Creator("Ribbits & Co. Club 6969 Silver Ed.", "RBECS") {}
}