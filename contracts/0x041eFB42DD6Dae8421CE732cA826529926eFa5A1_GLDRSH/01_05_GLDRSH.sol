// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GOLD RUSH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//           .....       .....     .....  .......          ......    ...  ...   ....   ..    ..               //
//            .,:cllcc,   .':cllc:,.  .:c;     ,cclc:'.        ,cccc:;. .:c;..;c:..,clll..,c:. .;c:.          //
//           .clc;'',;.  .:lc;'';clc' .cl;.    ,llc:cl:.       ;lc;,:lc..cl;..:l:.'llc,...;lc. .:l:.          //
//          .:lc.       .:lc'    .clc..co:.   .;ll,.,cl;.      ;lc'.;lc..cl;..:l:..clc,.  ;lc:,;cl:.          //
//          .cl:.   .;;..:l:.    .:oc..cl;.   .;ll,..cl:'.     ;lccclc. .cl;..:l:. .:ll:..;llcccll:.          //
//           ;ll;...;lc. ,ll;....;ll:.'lo:.....;ll:,:ll'.      ;lc;:lc' .cl:..cl:. .'cll,.;lc' .:l:.          //
//           .;cllcccll'  ,cllcclll;. 'loolll;.;ollol:'        ;lc..clc..;llccll, .:cllc..;lc. .:l:.          //
//             .',,;,,'.   .',;;,'.....;;;;;;..';;,,.          .,'. .,,. .',;;,.  .,;,'.  .,'.  .,'           //
//                                                                                                            //
//                                    .      ... ..    .... ....    .    ..                                   //
//                                   c0l.   .k0c..ox, .lKKx'.l0k,  .,.  ;Od.                                  //
//                                  .c0X:   .OWl  oWd. oMWk. .xNk..'.  .OXo'                                  //
//                                 .. cNO'  .OWc.cko.  oWMk.  .kNk;.   oWx...                                 //
//                                 .. .xNd. .OWc.dKl.  lNWk.   ,KNc   :X0,  ..                                //
//                                ..   ;KXc .OWl .xXl..dNWO.   '0Nc  'ONl   .'.                               //
//                               ...   .:l;..:c,  .::..;cc:.   .:l' .'cc.    ..                               //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GLDRSH is ERC721Creator {
    constructor() ERC721Creator("GOLD RUSH", "GLDRSH") {}
}