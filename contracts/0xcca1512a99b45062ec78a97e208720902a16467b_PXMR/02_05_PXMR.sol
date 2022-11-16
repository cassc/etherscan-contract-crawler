// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelMe Rewards
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                          .lkkkkkkkkkkl;.      .okkkkkkl.                                                      //
//                                                          .kWWWWWWWWWWOl'      '0WWWWWWk.                                                      //
//                                                      .lkkd:,,,,,,,,,,:ldkkkkkkd:,,,,,,cxkkkkkkc                                               //
//                                                      .kWW0'          .lOWWWWWWO.      ,0WWWWWWx.                                              //
//                           :kkx'                  .lkkx:,,'.............',,,,,,'........',,,,,,cxkkc               'xkk:                       //
//                          .dMMN:                  .kWW0,   ............         ........       ;XMMk.              :NMMd.                      //
//                       :OOO0KK0OOOOOOOOOOOOOOOOOOkxc,,'....................................    ;KMMNOOOOOOOOOOOOOOOO0KK0OOO:                   //
//                      .dMMWKOO0XMMMMMMMMMMMMMMMWWW0,   .....................................   ;XMMMMMMMMMMMMMMMMMWX0OOKWMMd.                  //
//                   :OOO0K0KXNNNX0K0KKKKKK0KNMMXl','        ....    .........................   ,KMMNK0KKKKKKKKKKKK0XNNNXK0K0OOO:               //
//                   dMMWKOOOXMMWKOOOOOOOOOO0XNWK,           ....    .........................   ,KWNX0OOOOOOOOOOOOOOKWMMXOOOKWMMo               //
//                   oMMWKOOOXMMWKOOOOOOOXNNKl'''........         ............        ............'''lKNNXOOOOOOOOOOOKWMMXOOOKWMMo               //
//                   oNNNKOO0XWWWKOOOOOOONMMX;   ........        .............        ............   ;XMMNOOOOOOOOOOOKWWWX0OOKNNNl               //
//                   .'',xNNNK000OOOOOOOONMMX;   ........................    .,;;'    ............   ;XMMNOOOOOOOOOOOO000XNNNx,''.               //
//                       oNNNKOOOOOOOOOOONMMX;   ........................    .:ll:.   ............   ;XMMNOOOOOOOOOOOOOOOKNNNo                   //
//                       .'',xNNNKOOOOOOONMMX;   ....................   ..,:;:lool:;:,.   ........   ;XMMNOOOOOOOOOOOKNNNx,''.                   //
//                           oNNXKOOOOOOOXWWX: ......................   .':llloddolll;.   .......    ;XMMNOOOOOOOOOOOKNNNo                       //
//                           .'.,kNNN0OOO00000O0x'   ....           .,:;:cloooddddoool:;:'.          ;XMMNOOOOOOOKNNNx,.'.                       //
//                               dMMWKOOOOOO0XNN0;   ....           .:lllooddddddddddolll;           ;XMMNOOOOOOOKWMMd                           //
//                               dMMWKOOOXNNXd::::::;.       ,:::::;:looodddddddddddddood:.  .,::,...cXMMN0OOOOOOKWMMd                           //
//                            . .xMMWKOOONMMNl.'':llc.      .:lllccccoddddddddooooddddddd:.  .cll:''.lNMMN0OOOOOOKWMMx. .                        //
//                           c000NMMWKOOONMMNl.',cool,...;:::oddl'...lxdddddxl...'lxdddddc'..,looc,'.lNMMNOOOOOOOKWMMN000c                       //
//                        ...xWWWWWWNKOOOXWWXo,,;lool;'',clllddxl.  .lxdddddxl.  .lxdddddl,'';lool;,,oXWWXOOOOOOOKWWWWWWWx...                    //
//                       c00000000000OOOO0000KKK0l,,;cllloooodddl.  .lxdddddxl.  .lddddddolllc;,,l0KKK0000OOOOOOOO00000000000c                   //
//            ...        lXXX0O000000000000O0NMMNo,,;loooodoododl.  .lxdddddxl.  .ldoooddooool;,,oNMMN0O00000000000000000KXXXl    ...            //
//           :00O;       ...'xWWWWWWWWWWWWWWWWMMWNKKOc,,;cllllllllcclodddddddolccllllllllc;,,cOKKNWMMWWWWWWWWWWWWWWWWWWWWx'...   ;O00:           //
//        ...dWWNl...........xMMMMMMMWWWWMMMMNXXXWMMXc..';cccccclooooodooooooooooolcccccc;'..cXMMWXXXNMMMMWWWWMMMMMMMMMMMx.......lNWWd...        //
//       :0K0000000KKKKKKKK0KNMMMMMMWX000NMMXc..,OMMK;    . ..,',clllllllllllllllc,','. .    ;KMMO,..cXMMNK00XWMMMMMMMMMMNK0KKKK0000000K0:       //
//    ...oWWWX000XWWWWWWWWWWWWWWWWWWNK000XWWK:..'xXXO'       ...'collllllllllllloc;,,.       'OXXx'..:KWWX000KNWWWWWWWWWWWWWWWWWWX000XWWWo...    //
//    KKK0000XWWNX0000000000000000000XWWNK0000KKO:...........   .okkxlccccccclxkkkxxxl...........:OKK0000KNWWX0000000000000000000XNWWX0000KKK    //
//    MMMXOOOXMMMXOOOOOOOOOOOOOOOOOOONMMWKOO0NMMK,   ........   .oOOkolllllllokOOOkxko'.......   ,KMMN0OOKWMMXOOOOOOOOOOOOOOOOOOOXWMMXOOOXMMM    //
//    MMMXOOOXMMMXOOOOOOOOOOOOOOOOOOONMMWKOO0NMMX;    ...;cc:'..,dOOOkkkkkkkkkOOOx:,,;:cc;...    ;KMMN0OOKWMMXOOOOOOOOOOOOOOOOOOOXWMMXOOOXMMM    //
//    KKK0000XWWWKOOOOOOOOOOOOOOOOOOOXWWNK000NMMK,   ....:llc,..,dOOOOOOOOOOOOOOOd;.',cll:....   ;KMMN000KNWWXOOOOOOOOOOOOOOOOOOOKNWWX0000KKK    //
//    ...dNWNX000OOOOOOOOOOOOOOOOOOOOO000XWWWWMMX;   ,c:coodl,'.,dOOOOOOOOOOOOOOOd,.',ldooc:c,   ;KMMWWWWX000OOOOOOOOOOOOOOOOOOOOO000XNWNd...    //
//       :KKK0000OOOOOOOOOOOOOOOOOOOO00000KKKWMMX;   ,:::lllc,..,dOkOOOOOOOOOkxxxo,..,clll:::,   ;KMMWKKK0000OOOOOOOOOOOOOOOOOOOOO0000KKK:       //
//        ...dWWNKOOOOOOOOOOOOOOOOOOOXWWXc..'OMMK,       ........okxkOOOOOOOOd,...........       ,KMMO'..cXWWXOOOOOOOOOOOOOOOOOOOKNWWd...        //
//           cKKK0000OOOOOOOOOOOOO0000KKO'  .oKKO:...           .cdodkOOOOOOOd. ..            ...:OKKo.  'OKK0000OOOOOOOOOOOOO0000KKKc           //
//            ...dWWWKOOOOOOOOOOOXWWXc...     ..'xXXO'           ...,dOOOOOOOd. .            'OXXx'..     ...cXWWXOOOOOOOOOOOKWWWd...            //
//               oMMWKOOOOOOOOOOOXMMX;          .kMMK,       .......,dOOOOOOOd,.......       ,KMMk.          ;XMMXOOOOOOOOOOOKWMMo               //
//               oMMWKOOOOOOOOOOOXMMX;          .kMMK,   .'.,oxxxxxxkkOOOOOOOkkxxxxxxo,.'.   ,KMMk.          ;XMMXOOOOOOOOOOOKWMMo               //
//            ..'xMMWKOOOOOOOOOOOXMMNl...       .kMMK,   .'.,oxxxxxxxdddddddddxxxxxxxo,.'.   ,KMMk.       ...lNMMXOOOOOOOOOOOKWMMx'..            //
//           cXXXWMMWKOOOOOOOOOOOXMMMNXX0,      .kMMK,   .......',,,'.........',,,'.......   ,KMMk.      ,0XXNMMMXOOOOOOOOOOOKWMMWXXXc           //
//       ...'dNNNNNNNKOOOOOOOOOOOXNNNNNNKc...   .o00k:.......................................:k00o.   ...cKNNNNNNXOOOOOOOOOOOKNNWNNNNd'...       //
//       cXXXK0OOOOOOOOOOOOOOOOOOOOOOO0O0KXX0,    ...xXXO'          .kXXXXXXXk.          'OXXx...    ,0XXK0O0OOOOOOOOOOOOOOOOOO0OOOO0KXXXc       //
//       :000000000000000000000000000000KNMMX;      .o00k:..........;x0000000x;..........:k00o.      'k0000000000000000000000000000000000:       //
//          .dWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMX;        ..'xNXNNNNNNXNO,.... . ,ONXNNNNNNXNx'..          . :XWWWWWWWWWWWWWWWWWWWWWWWWWWd.          //
//           :O0000000000000000000000NMMMWNNKl..........;0MMMMMMMWNN0:.'..   '0MMWWNNWMMM0;..............lKNNWMMMN0000000000000000000:           //
//                                  .kMMWKOO0KNNNNNNNNNNNWMMMMMMWKOO0XXNkc.  '0MMN0OOKWMMWNNNNNNNNNNNNNNNK0OOKWMMx. .                            //
//                               .'.,kNNNK00KXNNNNNNNNNNNNNNNNNNNK00KXNN0d:'':0NNXK00KNNNNNNNNNNNNNNNNNNNXK00KNNNk,''.                           //
//                               oNNXKOO0XWWWKOOOOOOOOOOOOOOOOOO0NWWN0OO0KXNNX0OOKNWWN0OOOOOOOOOOOOOOOOOOKWWWX0OOKXNNo                           //
//                               dMMWKOO0NMMWKOOOOOOOOOOOOOOOOOO0NMMN0OO0XNMMN0OO0NMMN0OOOOOOOOOOOOOOOOOOKWMMXOOOKWMMd                           //
//                               dMMWKOOONMMWKOOOOOOOOOOOOOOOOOO0NMMN0OO0XNMMN0OO0NMMN0OOOOOOOOOOOOOOOOOOKWMMXOOOKWMMd                           //
//                               cOOO000KXNNN0OOOOOOOOOOOOOOOOOO0XNNXK0000OOOO000KNNNX0OOOOOOOOOOOOOOOOOO0NNNXK000OOOc                           //
//                                  .xWWWKOOOOOOOOOOOOOOOOOOOOOOOOOO0NWW0o'  ,0WWN0OOOOOOOOOOOOOOOOOOOOOOOOOOKWWWx.                              //
//                                   cOOO0000OOOOOOOOOOOOOOOOOOOO0000OOOo;.  .oOOO0000OOOOOOOOOOOOOOOOOOOO0000OOOc                               //
//                                      .xMWWKOOOOOOOOOOOOOOOOOO0NWW0,           ,0WWN0OOOOOOOOOOOOOOOOOOKWWMx.                                  //
//                                       cOOO00K0OOOOOOOOOOOO0K00OOOo.           .oOkO00K0OOOOOOOOOOOO0K00OOOc                                   //
//                                          .kMWWKOOOOOOOOOO0NWW0,                   ,KWWN0OOOOOOOOOOKWWMx.                                      //
//                                          .xMMWKOOOOOOOOOO0NMM0'                   '0MMN0OOOOOOOOOOKWMMx.                                      //
//                                          .xMMWKOOOOOOOOOO0NMM0'                   '0MMN0OOOOOOOOOOKWMMx.                                      //
//                                       .,':0MMWKOOOOOOOOOO0NMMXl,,.             .,,lXMMN0OOOOOOOOOOKWMMO:,,.                                   //
//                                      .xWWWMMMWKOOOOOOOOOO0NMMMWWWO'           '0WWWMMMN0OOOOOOOOOOKWMMMWWWd.                                  //
//                                   .,,;kNNNNNNX0OOOOOOOOOO0XNNNNNN0c,,..    .,,c0NNNNNNX0OOOOOOOOOO0XNNNNNNk;,,.                               //
//                                  .dWWNKOOOOOOOOOOOOOOOOOOOOOOOOOO0NWWOl.  'OWWN0OOOOOOOOOOOOOOOOOOOOOOOOOOKWWWd                               //
//                                   :kkk0KKKKKKKKKKKKKKKKKKKKKKKKKK0kkkl,.  .okkk0KKKKKKKKKKKKKKKKKKKKKKKKKK0kkk:                               //
//                                      .xMMMMMMMMMMMMMMMMMMMMMMMMMM0'           '0MMMMMMMMMMMMMMMMMMMMMMMMMMx.                                  //
//                                      .xMMMMMMMMMMMMMMMMMMMMMMMMMM0'           '0MMMMMMMMMMMMMMMMMMMMMMMMMMx.                                  //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PXMR is ERC721Creator {
    constructor() ERC721Creator("PixelMe Rewards", "PXMR") {}
}