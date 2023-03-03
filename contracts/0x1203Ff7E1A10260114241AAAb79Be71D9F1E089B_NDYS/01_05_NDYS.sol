// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Notable Days
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                            .........                        .........                                                          //
//                            ,lllllll;''..                   .:olllllcoo,.                                                       //
//                            ;doododo:'',.                   .cdoooddlxNNk:.                                                     //
//                            ;doddodo:''',.                  .cdoddodokNMWW0o'.                                                  //
//                            ;doddodo:'',,'.                 .cdoddodlkWMWWWWXx;.                                                //
//                            ;dodoodo:',',,'.                .cdoddddlkWMWWWWWWNOc.                                              //
//                            ;doooodo:',,,,,'.               .cdoddddlxWMWWWWWWWWWKo,.                                           //
//                            ;doooddo;',,',,,'.              .cdoddddlxNMWWWkdKWWWWWXx:.                                         //
//                            ;doooddo,.,,,,,,,.              .cdoddddlxWMWWWo.'lONWWWWW0l.                                       //
//                            ;dddoodo'.',,,,,,,.             .cdoddddlxWMWMWo....:xXWWWWWXd,.                                    //
//                            ;dodoodo' .',',,,',.            .cdoddddlxWMWMWo......,dKWWWWWNk:.                                  //
//                            ;doddodo,  .',,,,,,'.           .cdoddddlxWMWMWo........'cONWWWWW0o'                                //
//                            ;doddooo,   .,'',,,,'.          .cdoddddlxWMWMWo...........;xXWWWWWXx;.                             //
//                            ;doodooo,    .,,,,,','.         .cdoddddlxWMWMWo.............,o0WWWWWNOc.                           //
//                            ;doodood,    .',',,',,.         .cdoddddlxWMWMWo................ckNWWWWWKo,.                        //
//                            ;doodood;     .',,,,,',.        .cdoddddlxWMWMWo..................;dXWWWWWXx;.                      //
//                            ;doodood;      .',,,,',,.       .cdoooddlxWMWMWo....................'l0NWWWMNOl.                    //
//                            ;dodddod;       .,,,,'','.      .cdoooddlxWMWMWo.......................:kXWWWWWKd,.                 //
//                            ;dodddod;        .,,',,','.     .cdoodddlxWMWMWo.........................lXMWWWWWNx'                //
//                            ;dodddod;        .',,,,',,.     .cdoddodlxWMWMWo.......................:xXWWWWWWXx:.                //
//                            ;dodddod;         .',,,,,,,.    .cdodoodlxWMWMWo....................,o0NWWWWWNOl'                   //
//                            ;dodddod;          .',,,',,,.   .cdodoodlxWMWMWo.................'ckXWWWWWWKd;.                     //
//                            ;dodddod;           .,,,,',,'.  .cdodoodlxWMWMWo...............;dKWWWWWWNOc.                        //
//                            ;dodddod;            .,,,,',,'. .:doododlxWMWMWo............'lONWWWWWWKd,.                          //
//                            ;dodddod;            .',,,',,,'  :doododlxWMWMWo..........:dKWWWWWWNk:.                             //
//                            ;dodddod;             .',,,,,,,..;doooodlxWMWMWo.......,lONWWWWWW0o'                                //
//                            ;dodddod;              .',,',,,'.;doodddlkWMWMWo.....:xXWWWWWWXx:.                                  //
//                            ;dodddod;               .,,,,',,,:odododlxWMWMWo..,o0NWWWWWNOl'                                     //
//                            ;dodddod;                .,,,,,',codododlxNMWWWxckXWWWWWWXx;.                                       //
//                            ;dodddod;                .',',,',codooddlxNMWWWNWMWWWWNOc.                                          //
//                            ;dodddod;                 .',',,,codooddlxWMWWWWWWWWKd,.                                            //
//                            ;dodddod;                  .',,',codooddlkWMWWWWWNk:.                                               //
//                            ;doooood;                   .'',,codooodlxNMWWW0o,                                                  //
//                            ;dooodod;                    .,',cooooodlxNMXx:.                                                    //
//                            ;ooooooo;                     .',cooooooldOl'                                                       //
//                            .........                        ..........                                                         //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NDYS is ERC721Creator {
    constructor() ERC721Creator("Notable Days", "NDYS") {}
}