// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Mahnaji Ani-Editions 1/1s
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//      xx         xx   xx      xxx        xxx               xx                                  xx   xx      //
//      xx         xx   xx      xxxx      xxxx               xx                                  xx   xx      //
//      xx              xx      xxxx      xxxx               xx                                               //
//      xx              xx      xxxx      xxxx               xx                                               //
//      xx              xx      xx xx    xx xx               xx                                               //
//      xx         xx   xx      xx xx    xx xx     xxxxx     xx xxxx     xx xxxx       xxxxx     xx   xx      //
//      xx         xx   xx      xx xx    xx xx    xxxxxxx    xxxxxxxx    xxxxxxxx     xxxxxxx    xx   xx      //
//      xx         xx   xx      xx xx    xx xx   xx     xx   xxx   xxx   xxx   xxx   xx     xx   xx   xx      //
//      xx         xx   xx      xx  xx  xx  xx          xx   xx     xx   xx     xx          xx   xx   xx      //
//      xx         xx   xx      xx  xx  xx  xx     xxxxxxx   xx     xx   xx     xx     xxxxxxx   xx   xx      //
//      xx         xx   xx      xx  xx  xx  xx    xxxxxxxx   xx     xx   xx     xx    xxxxxxxx   xx   xx      //
//      xx         xx   xx      xx   xxxx   xx   xxx    xx   xx     xx   xx     xx   xxx    xx   xx   xx      //
//      xx         xx   xx      xx   xxxx   xx   xx     xx   xx     xx   xx     xx   xx     xx   xx   xx      //
//      xx         xx   xx      xx   xxxx   xx   xx    xxx   xx     xx   xx     xx   xx    xxx   xx   xx      //
//      xxxxxxxxxx xx   xx      xx    xx    xx   xxxxxxxxx   xx     xx   xx     xx   xxxxxxxxx   xx   xx      //
//      xxxxxxxxxx xx   xx      xx    xx    xx    xxxxx xx   xx     xx   xx     xx    xxxxx xx   xx   xx      //
//                                                                                               xx           //
//                                                                                               xx           //
//                                                                                               xx           //
//                                                                                              xxx           //
//                                                                                              xx            //
//                                                                                                            //
//                                      xx                                                                    //
//                 x                    x                                 x                          x        //
//                xx                                                     x                          x         //
//               x xx                                                    x                          x         //
//              x  xx                                                    x                          x         //
//             x   xx     x  xxxx     x    x  xxxx   xxx       xxxx   xxxxxx      xxxx         xxx x          //
//             x   xx     x x   x     x    x x   xxxx  x     xx  xx     x        x    x      xx  xxx          //
//            x    xx     xx    x     x    xx    xx    xx   x     x     x       x     x     x     xx          //
//           x     xx    x      x    x    x      x     x         x     x       x      x    x      x           //
//           xxxxxxxx    x      x    x    x      x     x       xxx     x      xxxxxxxxx    x      x           //
//          x      xx    x      x    x    x      x     x    xxx  x     x      x            x     xx           //
//         x       xx   x      x    x    x      x     x    x    x     x       x           x      x            //
//         x       xx   x      x    x    x      x     x   x     x     x      xx           x     xx            //
//        x        xx   x      x    x    x      x     x   x     x     x      xx      x    x     xx            //
//       x         xx  x      x    x    x      x     x   xx   xx     x        xx   xx     xx   xx             //
//                   x      x         x      x     x    xxxx xx    xxxx      xxxx        xxxx x               //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//      xxxxxxxxxxxx            xx      xx               xx                                                   //
//      xxxxxxxxxxxx            xx      xx               xx                                                   //
//      xx                      xx              xx                                                            //
//      xx                      xx              xx                                                            //
//      xx                      xx              xx                                                            //
//      xx                 xxxx xx      xx     xxxxx     xx        xxxxx        xx xxxx          xxxx         //
//      xx                xxxxxxxx      xx     xxxxx     xx       xxxxxxx       xxxxxxxx       xxxxxxxx       //
//      xxxxxxxxxxx      xxx   xxx      xx      xx       xx      xxx   xxx      xxx   xxx      xx    xx       //
//      xxxxxxxxxxx      xx     xx      xx      xx       xx      xx     xx      xx     xx      xx             //
//      xx               xx     xx      xx      xx       xx      xx     xx      xx     xx      xxxxx          //
//      xx               xx     xx      xx      xx       xx      xx     xx      xx     xx        xxxxx        //
//      xx               xx     xx      xx      xx       xx      xx     xx      xx     xx           xxx       //
//      xx               xx     xx      xx      xx       xx      xx     xx      xx     xx            xx       //
//      xx               xxx   xxx      xx      xx       xx      xxx   xxx      xx     xx      xx    xx       //
//      xxxxxxxxxxxx      xxxxxxxx      xx      xxxx     xx       xxxxxxx       xx     xx      xxxxxxx        //
//      xxxxxxxxxxxx       xxxx xx      xx       xxx     xx        xxxxx        xx     xx        xxxx         //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LilMaAniEd1s is ERC721Creator {
    constructor() ERC721Creator("Lil Mahnaji Ani-Editions 1/1s", "LilMaAniEd1s") {}
}