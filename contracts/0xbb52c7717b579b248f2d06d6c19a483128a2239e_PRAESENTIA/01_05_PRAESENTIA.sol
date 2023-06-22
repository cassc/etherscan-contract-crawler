// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Atelier: Praesentia
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                           .::.                                                                 //
//                                                          ,0WW0,                                                                //
//                                                         ,OWMMW0o,                                                              //
//                                                        ,OMMMMMMM0;                                                             //
//                                                       ,0MMMMMMMMM0:                                                            //
//                                                      ,OWMMMMMMMMMWK;                                                           //
//                                                     ,OWMMMMMMMMMMMW0,                                                          //
//                                                    ,0WMMMMMMMMMMMMMW0;                                                         //
//                                                   ,OMMMMMMMMMMMMMMMMM0;                                                        //
//                                                  ,OMMMMMMMMMMMMMMMMMMM0;                                                       //
//                                                 ,OWMMMMMMMMMMMMMMMMMMMM0;                                                      //
//                                                ,0WMMMMMMMMMMMMMMMMMMMMMWK;                                                     //
//                                               ,OWMMMMMMMMMMMMMMMMMMMMMMMW0;                                                    //
//                                              ,OWMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                                   //
//                                             ,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                                  //
//                                            ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                                 //
//                                           ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;                                                //
//                                          ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,                                               //
//                                         ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;                                              //
//                                        ,OMMMMMMWWNNWMMMMMMMMMMMMMMMMMWNNWWMMMMMM0;                                             //
//                                       ,OMMMMMMXo,''lKWMMMMMMMMMMMMMMKl,',oKMMMMMM0;                                            //
//                                      ,0WMMMMWk'     .oXMMMMMMMMMMMNd.     .xNMMMMMK;                                           //
//                                     ,0WMMMMMNc       '0MMMMMMMMMMMX;       :XMMMMMWK;                                          //
//                                    ,0WMMMMMMWKl.   .:ONMMMMMMMMMMMW0c.   .c0WMMMMMMWK;                                         //
//                                   ,0WMMMMMMMMMW0dooOWMMMMMMMMMMMMMMMW0ood0WMMMMMMMMMM0;                                        //
//                                  ,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                       //
//                                 ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                      //
//                                ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK:                                     //
//                               ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;                                    //
//                              ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                   //
//                             ,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                  //
//                            ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:                                 //
//                           ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:                                //
//                          ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;                               //
//                         ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK;                              //
//                         cXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNXl                              //
//                          ........................................................................                              //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PRAESENTIA is ERC1155Creator {
    constructor() ERC1155Creator("The Atelier: Praesentia", "PRAESENTIA") {}
}