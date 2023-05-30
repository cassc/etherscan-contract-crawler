// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Resatio
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//        xxxxx                                           x                  x                                     //
//       xxxx  xx          xxxxxxxxx         x x          xx                xxx         xx         xx              //
//       xx  xxxxxxxx      x       x        xxxx          xxx               xx x        xx       xxxxxxxxx         //
//       xx      xxxxx             x       xxx           xxxxx               x x        x        xx      xxx       //
//       xx         xxx             x     xx             x xxxx        xxx xxxxxxxxx    xx      xxx       xxx      //
//       xx       xxxxx             x     xx             x  xx x      xxxxxxxxxxxxx     xx      xx         xx      //
//      xxx    xxxx                 x    xxxxx          xx   xxx            xxx        xxx      xx         xx      //
//      x xxxxxxx              xxxxxx       xxxx        xx    xxxx           xx        xxx     x x         x       //
//      x xxxx xx           xxxxxxxxx         xxxx     xxx xxxxxxx          xx         xxx     x x        xx       //
//     xxx    xxxxx                 x          xxx     xxxxx    xxx         xxx        xxx     x x       xxx       //
//    xxxx      xxxxx               xx        xxx      xxx      xxx         xxx        xxx     xxxx      xx        //
//    xx x         xxxx              x       xxx       xx        x x        xxx        xxx      xxxx   xxx         //
//    xx x          xxxx             x       xx       xxx        x  x       xx         xx        xxxxxxxx          //
//      xx           xxx      x    xxxx     xx        x x            x     xxx         xx                          //
//      x              x      xxxxxx        xx         xx                  xx           x                          //
//                                                                                                                 //
//                                                                                                                 //
//                                                            x xx  xx x                            xxxxxxxxxxx    //
//                                    x  x x x x x  x xx x xxx x x x  xxxxxxxxxx xxxxxxxxxxx xxxxxxx xxxxxxxx      //
//           x xxx xx  xxxxxxxx xxx x x x  x   x x xxxxx xx xx  xx xx                       x x xx xx  xxx         //
//     x xx x                         x x xx xx  x                                                                 //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RST is ERC721Creator {
    constructor() ERC721Creator("Resatio", "RST") {}
}