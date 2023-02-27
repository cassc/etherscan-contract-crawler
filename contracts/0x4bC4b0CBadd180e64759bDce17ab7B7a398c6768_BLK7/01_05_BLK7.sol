// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLACK7EVEN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                              7EVE                                                          //
//                                            [email protected]@@@NB                                                        //
//                                           [email protected]@@@@@@@L                                                       //
//                                           [email protected]@@@@@@@A       EVENBLA                                         //
//                             BLACK7        [email protected]@@@@@@@C      [email protected]@@@@@@C                                        //
//                            [email protected]@@@@@E       [email protected]@@@@@@@K      [email protected]@@@@@@K                                        //
//                           [email protected]@@@@@@V       [email protected]@@@@@@@@7    [email protected]@@@@@@@7         ENBLAC                         //
//                           [email protected]@@@@@@@E      [email protected]@@@@@@@@E    [email protected]@@@@@@@E        [email protected]@@@@@K                        //
//                           [email protected]@@@@@@@N      [email protected]@@@@@@@@V    [email protected]@@@@@@@V       [email protected]@@@@@@@7                       //
//                           [email protected]@@@@@@@B      [email protected]@@@@@@@@E    [email protected]@@@@@@@E       [email protected]@@@@@@@E                       //
//                           [email protected]@@@@@@@@L     [email protected]@@@@@@@@N    [email protected]@@@@@@NB      [email protected]@@@@@@@V                        //
//                           [email protected]@@@@@@@@A     [email protected]@@@@@@@@B    [email protected]@@@@@@L      [email protected]@@@@@@@@E                        //
//                           [email protected]@@@@@@@@C     [email protected]@@@@@@@@L   [email protected]@@@@@@@A      [email protected]@@@@@@@N                         //
//                            [email protected]@@@@@@@K     [email protected]@@@@@@@@@A  [email protected]@@@@@@@C     [email protected]@@@@@@@@B                         //
//                            [email protected]@@@@@@@@7    [email protected]@@@@@@@@@C [email protected]@@@@@@@K     [email protected]@@@@@@@L                          //
//                            [email protected]@@@@@@@@@E   [email protected]@@@@@@@@@K [email protected]@@@@@@@@7    [email protected]@@@@@@@@A      NBLACK              //
//                            [email protected]@@@@@@@@@V   [email protected]@@@@@@@@@[email protected]@@@@@@@@@E    [email protected]@@@@@@@C     [email protected]@@@@7E             //
//                            [email protected]@@@@@@@@@E   [email protected]@@@@@@@@[email protected]@@@@@@@@@V   [email protected]@@@@@@@@K     [email protected]@@@@@@V             //
//                             [email protected]@@@@@@@@@N   [email protected]@@@@@@@@[email protected]@@@@@@@@@E  [email protected]@@@@@@@@@7    [email protected]@@@@@@E              //
//                             [email protected]@@@@@@@@@B  [email protected]@@@@@@@@[email protected]@@@@@@@@N   [email protected]@@@@@@@@E    [email protected]@@@@@@@N               //
//                              [email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@B  [email protected]@@@@@@@@@V   [email protected]@@@@@@@B              //
//                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@E   [email protected]@@@@@@@L               //
//          LACK7EV             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N   [email protected]@@@@@@@@A                //
//         [email protected]@@@@@@EN            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@&B  [email protected]@@@@@@@@CK                //
//         [email protected]@@@@@@@@BL          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@L  [email protected]@@@@@@@@@7                 //
//          [email protected]@@@@@@@@AC         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@A [email protected]@@@@@@@@@E                  //
//           [email protected]@@@@@@@@@K        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@V                   //
//           [email protected]@@@@@@@@@7       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@EN                    //
//            [email protected]@@@@@@@@@E      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B                     //
//             [email protected]@@@@@@@@@V     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@L                      //
//              [email protected]@@@@@@@@EN   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@A                       //
//              [email protected]@@@@@@@@@BL [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@C                       //
//               [email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@K                        //
//               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7                        //
//                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                         //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@V                         //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                           //
//                   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N                          //
//                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B                          //
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@L                           //
//                      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@A                           //
//                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@C                            //
//                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@K7                            //
//                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                             //
//                             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@V                              //
//                               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                               //
//                                  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N                                //
//                                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B                                 //
//                                      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@L                                  //
//                                      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@A                                  //
//                                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@C                                 //
//                                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@K                                 //
//                                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7                                 //
//                                        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                                 //
//                                        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@V                                 //
//                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@E                                 //
//                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N                                 //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BLK7 is ERC1155Creator {
    constructor() ERC1155Creator("BLACK7EVEN", "BLK7") {}
}