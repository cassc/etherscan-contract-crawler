// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blue Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//    |¯¯¯¯|\¯¯¯¯\‚ |¯¯¯¯|'          |¯¯¯¯|'  |¯¯¯¯|             '/¯¯¯¯/\¯¯¯¯\‚  |¯¯¯¯|\¯¯¯¯\'  /¯¯¯¯/\¯¯¯¯\'                                    //
//    |:·.·.·:|/____/| |:·.·.·:|'          |:·.·.·:|'  |:·.·.·:|             |:·.·.·:|:/____/|  |:·.·.·:| |:·.·.·:| |\:·.·.·:\:'|____|‚          //
//    |:·.·.·:|\¯¯¯¯\| |:·.·.·:|/¯¯¯¯\' |:·.·.·:|'  |:·.·.·:|             |:·.·.·:|'|/¯¯¯¯/|‚ |:·.·.·:|\|:·.·.·:| |¯¯¯¯|:'\:·.·.·:\|‚            //
//    |____|/____/| |‚____/|____| |\____\/____/|             |____|/____/':|' |____|/____/|‚|\____\/____/|                                       //
//    |'¯`·v´·||'¯`·v´|'| |¯`·v·´|:|'¯`v.´’| |:|'¯`·v´||'¯`·v´|:|             |'¯`·v´·||'¯`·v´|':/‚ |'¯`·v´·||'¯`·v´|'|‚|:|'¯`·v´||'¯`·v´|:|     //
//    |L,__,||L,__'|/'‚|L,__'|/|L,__,| '\|L,__'||L,__'|/'             |L,__,||L,__'|/'‚  |L,__,||L,__'|/ '\|L,__'||L,__'|/'                      //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract blueds is ERC1155Creator {
    constructor() ERC1155Creator("Blue Editions", "blueds") {}
}