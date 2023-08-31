// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peculiar Fossil
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//                                                                                                              //
//                                          ............                                                        //
//                       .  .......        .'lddddddddo,.        .......                                        //
//                         .,dkkkxxoc'.     .dXNNNNNNXd.     .':lddxxxd,.                                       //
//                         .;0NNNNNNNKo'.    ,ONNNNNNO,    .'o0XNNNNNN0:.                                       //
//                          .;ldOXNNNNNd.    .xNNNNNNx'    .dXNNNNXOxo:.                                        //
//                             ..dXNNNNO,    .xNNNNNNx.    ,ONNNNXd....                                         //
//                              .:0NNNNO,    .xNNNNNNx.    ;0NNNN0:.                                            //
//                              .;0NNNNO,    .xNNNNNNx.    ,ONNNN0;.                                            //
//                              .:KNNNN0;.   .xNNNNNNx.    ;0NNNN0;.                                            //
//                               ;0NNNN0:.   .xNNNNNNx.   .:KNNNNO,                                             //
//                               .xNNNNXd.   ,ONNNNNNO,   .dNNNNXd.                                             //
//                               .:0NNNNXxc;ckXNNNNNNXxc;cxXNNNN0;.                                             //
//                                .:ONNNNNNXNNNNNNNNNNNNXNNNNNXO:.                                              //
//                                 .'l0NNNNNNNNNNNNNNNNNNNNNN0l'.                                               //
//                                   .,lOKNNNNNNNNNNNNNNNNXOl,.                                                 //
//                                     ..,cdkKNNNNNNNNKkdc;..                                                   //
//                                         ..;ONNNNNNk;..                                                       //
//                                           'kNNNNNNx.      .                                                  //
//                                          .cKNNNNNN0:.                                                        //
//                                          'xKXXXXXXKd'                                                        //
//                                          .'',,,,,,,'.                                                        //
//                                                                                                              //
//        Handheld relic. Petrified to stone, dried blood and sinew residue show a past of exploitation.        //
//                                                                                                              //
//        Remnant sanguis and bone, cartilage, a once soft sentient tendril, now hardened and decayed.          //
//                                                                                                              //
//        Burning metal emanates omens of near-disaster.                                                        //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FOSSIL is ERC1155Creator {
    constructor() ERC1155Creator("Peculiar Fossil", "FOSSIL") {}
}