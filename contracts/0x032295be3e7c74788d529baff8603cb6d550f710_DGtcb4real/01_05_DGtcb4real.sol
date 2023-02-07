// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dysfunctional Glitch by tcb4real
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                      xx                                                        //
//                                                                                                     x x                                                        //
//                                                     xxxxx       xxx                                x  x                                xxx                     //
//                            xxxx        xxx      xxxx    xxxxxxxxx xxx     xxx                    xx    xxxxx                          x  xx                    //
//                    xxxxxxxxx  x     xxx   xxxxxx                     xxxxx  xxxxxxxxxxxxx      xx          xxxx    xx    xxxx        x    xx                   //
//             xxxx   x  xx       xxxxx                                                     x     x             xxxxxx xxxxx   xxx    x       x                   //
//       xx   xx  xxxx                                                                       xxxxxx                               xxxx         x                  //
//     xxxxxx                                                                                                                                   x  x              //
//     x                                                                                                                                        xxxx              //
//     x                                                                                                                                           xx             //
//     xx                                         xxxxxx                                x       xx                                                  x             //
//     xx                                        xx    xx                               x       xx                                  x               x             //
//     xx                          x             x      x           x            xxx    x                        x                  x               x             //
//     xx                 xx       x    xxx      x                  xxx xx     xx       x       x     xxxxxx     xxxxx      xxxx    x               x             //
//     x        xxxxxxxx    xx    x   xxx xx     x                    xxxxx    x        x       x    x     xx    x   xx   xxx  x    x               x             //
//    xx        x      xx     xx x    x          x       x       x    x   xx  xx     xxxxxxx    x   x       x    x    x  xx    x    x               x             //
//    xx        x       x      xxx    x       xxxxxxx    x       x    x    x  x         x       x   x       x    x    x  x     x    x               x             //
//     xx       x       x      x      x           x      x       x   xx    x  x         x       x   xx     xx   xx    x  x     x    x               x             //
//     xx       x      xx     xx      xxxxxxxx    x      xx     xxx  x     x  x         x       x    xxxxxxx    x     x  xx    xx   xx              x             //
//     xx      xx    xxx     xx              x    x        xxxxx  x  x     x  xx         x      x               x     x   xxxxx x    x              x             //
//     xx      xxxxxx        x              xx    x                            xxxxxx    x                      x     x      xx x    xxxxxx         x             //
//     xx                   xx       xxxxxxxx     x                                      x                                                          x             //
//    x                     x                                                            x                                                          x             //
//    x                                                                                                                                             x             //
//    x                                                                  x             xxxxxxxxxxxxxxxxxxxxxxxxxxx          x             x         x             //
//    x                    xxxxxxxxx         x                           x                       x                  xxx     x             x         x             //
//    x           xxxxxxxxx                  x                           x                       x                xxx       xxxxxxxxxxxxxxx         x             //
//    x         xx                xxxxxxx    x                           x                       x                x         x             x         x             //
//    x         x                      x     x                           x                       x                 xxxxxx   x             x         x             //
//    x         x                      x     x                           x                       x                                                  x             //
//    xx        xxxxxxxxx              x     xxxxxxxxxxxxxxxxxxx                                                                                    x             //
//     xx                xxxxxxxxxxxxxx                                                                                                             x             //
//     xx                                                                                                                                           x             //
//      x                                                                                                                                        xxxx             //
//      xx                          x                            x               x           x                                         xxxxxxxxxx                 //
//      xxx            x      xx    x              x             x               x           x                                xxxxxxxxx                           //
//        xx           x       x   xx              x             x               x           x                          xxxxxx                                    //
//         x           x xxxx   xxxxx              x             xxxxxxxx        x           x                         xx                                         //
//         x           xx   xx      x              x             x      xx       x           x                        xx                                          //
//         x           xx    x      x              x        x    x       x       x           x                       x                                            //
//         x           x     x      x          xxxxxxxxx  xx     xxxx   xx       xxxxxxxxxxxxxxx                    x                                   xxx       //
//      x x            xx   xx      x              x     xx         xxxxx                    x                    xx        xxxxxxx     xxxxxxxx          xxxx    //
//      x              xxxxxx                      x     x                                   x                    x       xxx     xx  xxx      xxx         xxx    //
//      x                                          x      xx     xx                          x                   x       xx        xxxx          xx     xxx x     //
//      xx                                         x       xxxxxxx                           x                  xx      x           x             x  xxxx   x     //
//      xx                                                                                   x                  x       x                       xxxxx       x     //
//      x                                                                                                       x       x                    xxx  x               //
//      xx                                                                     x                               x        x                 xxx     x               //
//       x                       xxxxxxxx          xxxxxxxx         xxxxxxx    x                               x        x              xxx       xx               //
//       x                       x      xxx        x              xxx     x    x                              x         x              x         x                //
//       x                       x        xx       x             xx       x    x                              x         xx                       x                //
//       x                       x         x       x             x        x    x                              x          x                      xx                //
//       x                       x         x       x             x        x    x                             xx         xxx                    xx                 //
//       x                       x         x       x             x        x    x                             xxxx    xxx  xx                  xx                  //
//       x                       x       xx        xx            x        x    x                             x   xxxx       x                xx                   //
//       x                       xxxxxxxxx          xxxxxxx      xxxxxxxxxxx   x                             x    x         xx             xx                     //
//       x                       x        xx        x            x         x   x                             x    x          x            xx                      //
//       x                       x         xx       x            x         x   x                             x    x           xx         xx                       //
//       x                       x          x       x            x         x   x                            x     x             x       xx                        //
//       x                       x          xx      x            x         x   x                            x     x              xx   xxx                         //
//       x                       x           x      x            x         x   xxxxxxxxx                    x                      xxxx                           //
//       x                       x           x      x            x         x                               xx                      xx                             //
//       x                       x           x      xxxxxxx      x         x                               x                                                      //
//       xx                                  x                             x                              xx                                                      //
//       xxx                                                                                            xxx                                                       //
//         x                                                                                   xxx xxxxxx                                                         //
//         xx                                                                   xxxxxxxxxxxxxxxx                                                                  //
//          x         xxxxxxx            xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                                                                                  //
//          xx     xxx       xxxxxxxxxxxx                                                                                                                         //
//            xxxxx                                                                                                                                               //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DGtcb4real is ERC1155Creator {
    constructor() ERC1155Creator("Dysfunctional Glitch by tcb4real", "DGtcb4real") {}
}