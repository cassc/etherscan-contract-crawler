// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AIIA DAO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                            .....               ...            ...               .....                                //
//                       .:dOKXXXKOdc.         ;O0000o.      .o0000k,         .cxOKXXXKOd:.                             //
//                     .oXMMMMMMMMMMMXo.      .xMMMMMK,      ;XMMMMMd       .dXMMMMMMMMMMWKl.                           //
//                    .xWMMMMMMWMMMMMMWk.     .xMMMMMK,      ;XMMMMMd      .OMMMMMMMWMMMMMMWd.                          //
//                    cNMMMMM0c,:OWMMMMWc     .xMMMMMK,      ;XMMMMMd      lWMMMMWO:,c0MMMMMX:                          //
//                    oMMMMMN:   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd      dMMMMMX;   cWMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMNl...lNMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMXc...oWMMMMWl                          //
//                    oMMMMMMNKKKNMMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMMNKKXWMMMMMWl                          //
//                    oMMMMMMMMMMMMMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMMMMMMMMMMMMWl                          //
//                    oMMMMMMWNNNWMMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMMWNNWWMMMMMWl                          //
//                    oMMMMMWd'''oNMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMNo'''xWMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oMMMMMX;   ;XMMMMMd     .xMMMMMK,      ;XMMMMMd     .xMMMMMK,   :NMMMMWl                          //
//                    oWMMMMX;   ,KMMMMMo      dMMMMMK,      ,KMMMMMo      dMMMMM0'   :NMMMMWc                          //
//                    .ldddd:.   .:odddl.      'ldddo;       .:odddl.      'odddo;    .cddddc.                          //
//                                                                                                                      //
//                        .........                      ......                    ......                               //
//                     .x000000000Oko;.             .cxOKXNNXKOxc.             'lk0XNNXKOd;.                            //
//                    :NMMMMMMMMMMMMWKo.         .dXMMMMMMMMMMMMXo.         ,kNMMMMMMMMMMW0c.                           //
//                    :NMMMMMMMMMMMMMMMO'       .kWMMMMMMWWMMMMMMWk.       ;KMMMMMMWWMMMMMMNo                           //
//                    :NMMMMMO:,cOWMMMMWd       cWMMMMWO:,,:OWMMMMNc      .xMMMMMNx;,lKMMMMMK,                          //
//                    :NMMMMWl   '0MMMMMk.      dMMMMMX;    :NMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMX;    ;XMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMX;    ;XMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMX;    ;XMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMNl....oNMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMMWXKKXWMMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMMMMMMMMMMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMMWNNNNWMMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMNo'..'dWMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMX;    ;XMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   .OMMMMMk.      dMMMMMX;    ;XMMMMMo      .OMMMMMO.   oMMMMMN:                          //
//                    :NMMMMWl   :XMMMMMx.      dMMMMMX;    ;XMMMMMo      .kMMMMMK,  .xMMMMMX;                          //
//                    :NMMMMMKxdkNMMMMMWl       dMMMMMX;    ;XMMMMMo       oWMMMMW0dokNMMMMMO.                          //
//                    :NMMMMMMMMMMMMMMNd.       dMMMMMX;    ;XMMMMMo       .kWMMMMMMMMMMMMMK;                           //
//                    :NMMMMMMMMMMMWKx,         oMMMMMK,    ;XMMMMWo        .cONMMMMMMMMWKd'                            //
//                    .:odddddddooc,.           .ldddo;     .:odddl.           'coxkkxdl;.                              //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AIIA is ERC721Creator {
    constructor() ERC721Creator("AIIA DAO", "AIIA") {}
}