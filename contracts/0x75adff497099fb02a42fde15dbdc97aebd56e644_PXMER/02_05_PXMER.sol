// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelMe Rewards
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                            'xkkkkkkk;      :kkkkd'                                         //
//                                         .,;cdxxxxxxxl::;;;:lxxxxdc;;;;,.                                   //
//                                         :KWd        lXNWNWX:    .dWNNW0,                                   //
//                    .lOd.             'xOo,'..........''''''.......'''';dOd.          .dOc                  //
//                  ':lOX0o:::::::::::::cod:. ..........      .......    .kMXd::::::::::oKXOc:'               //
//                 .kWNKO0NWWWWWWWWMMWNNd.  ...........................  .kMMWWWWWWWWWWWN0OKWWx.              //
//               l0000KXNNK0000000KWM0;..     ....  ...................  .kMWK0000000000KNNXK0000c            //
//              .xMWKO0NMW0OOOO0KK0do:.....    ..   ........  .......... .:od0KK0OOOOOOOKWMN0OKWMd            //
//               oXK0O0NWN0OOOO0NMO.  ......      .........       ........  .OMN0OOOOOOO0NWX0O0XXl            //
//               ..,kWNK00OOOOO0NMO.  .................    .::.   ........  .OMN0OOOOOOOO00KNWk'..            //
//                  ,loOXK0OOOO0NMO.  ...............  .''':ol;'..  ......  .OMN0OOOOOOO0KXOol,               //
//                    .oKK000OO0NWO,.................  ,llloddoll'  ......  .OMN0OOOOO000KKo.                 //
//                     ..,OWN0OOO00KXd.  ...        .:cloooddddoolc:.       .OMN0OOOO0NWk'..                  //
//                       .OMN0O0KX0xdl,'..    .''''':ooodddddddddool.  .''..,OMN0OOOO0WMk.                    //
//                     ..;0MN0O0NM0;.,co;.  ..'loc::lddddddlccoddddo' .;ol,.;0MN0OOOO0WMO;..                  //
//                    .dXNWMN0O0NM0;.;odc'.,:cldd;  ,dddddd, .;ddddo;.'cdo;.;0MN0OOOO0WMWNXd.                 //
//                  ;ddOKKKKKOOOKK0kxdc:::ccooodd;  ,dxddxd,  ;ddddolc:::cdxk0KKOOOOO0KKKKKOdd;               //
//         .'.      lOO00000000000KWMKl:clllooooo:..;dddddd;..;ooooolllc:lKMWK00000000000000OOc   .'.         //
//         lNK;       .kWWWWWWWWWWMMMMWWO;';lllllloooddddddooollllll;';OWWMMMMWWWWWWWWWWWWWk.    ;KNl         //
//      ,dxOKKkdddddddkXMMMMWXKXWMKl;dNMk. ...',;:looooooooool:;,'... .kMNd;lKMWXKXWMMMMMMMXxddddkKKOxd,      //
//    ',xNNX0KXNNNNNNNNNNNNNXK0KXNO:'cxOl.     ..;oollllllllooc:;.    .lOxc':ONXK0KXNNNNNNNNNNNNNXK0XNNx,'    //
//    WWKOOXWWKOOOOOOOOOOOOO0NMN0O0NWk.  .....   ,kOdccccccdOOkOk;.....  .kWN0O0NMN0OOOOOOOOOOOOOKWWXOOKWW    //
//    MMXOOXMWKOOOOOOOOOOOOO0NMN0O0WMk.  ...;;,..:kOkxxxxxxkOko:::;;...  .kMW0O0NMN0OOOOOOOOOOOOOKWMXOOXWM    //
//    kkOKKXNX0OOOOOOOOOOOOO0XNXKKXWMk.  ..,lo:''ckOOOOOOOOOOkc.':ol,..  .kMWXKKXNX0OOOOOOOOOOOOO0XNXKKOkk    //
//      lWWKOOOOOOOOOOOOOOOOOOO0NWWMMk. .:llooc'.ckOOOOOOOOOOkc.'cooll:. .kMMWWN0OOOOOOOOOOOOOOOOOOOKWWl      //
//      .,;xNN0OOOOOOOOOOOOO0XNOc,lXMk.  ....'...;xkkOOOOOkl,'....'....  .kMXl,cONX0OOOOOOOOOOOOO0NNx;,.      //
//         ;xxOKK0OOOOOOOO0K0kxc. .lxo:;'        .ccdOOOOOk:..         ';:oxl. .cxk0K0OOOOOOOO0KKOxx;         //
//            dMWKOOOOOOO0NM0'       ,KMx.        ..:kOOOOk:..        .xMK,       '0MN0OOOOOOOKWMd            //
//            dMWKOOOOOOO0NM0'       ,KMx.  ..;looddxOOOOOOxddool;..  .xMK,       '0MN0OOOOOOOKWMd            //
//         .:c0MWKOOOOOOO0NMXo:,     ,KMx.  ..;llloolccccccloolll;..  .xMK,     ,:oXMN0OOOOOOOKWM0c:.         //
//        .dWWWWWKOOOOOOO0NWWWWO,    'ONx. ........'..    ..'........ .xNO'    ,OWWWWN0OOOOOOOKWWWWWd.        //
//      :O0000000OOOOOOOOO00000000o.  ..:k0l.       :O0000O:       .l0k:..  .o00000000OOOOOOOOO0000000O:      //
//      'odOKKKKKKKKKKKKKKKKKKKXWMO.    .colccccccccloooooolccccccccloc.    .:od0KKKKKKKKKKKKKKKKKKKOoo,      //
//         lXXXXXXXXXXXXXXXXXWMMWWO,.......cNMMMMWWWd..    oMMWWWWMNc..........,OWWMMWXXXXXXXXXXXXXXl         //
//         .................;0MNK0000KKKKKKXWMMMMN00000:   oMWX00NMWXKKKKKKKKK0000KWM0;..............         //
//                        ;lo0XXXKXXXXXXXXXXXXXXXXXXXXKklllkXXXXXXXXXXXXXXXXXXXXXKXXXOol;                     //
//                       .kMN0k0NMN0OOOOOOOOOOOOOKWMXOOXWMWXOOXMWKOOOOOOOOOOOOO0NMN0k0WMk.                    //
//                       .kMN0k0NMN0OOOOOOOOOOOOOKWMXOOXWMWXOOXMWKOOOOOOOOOOOOO0NMN0k0WMk.                    //
//                        ,co0XXXKKOOOOOOOOOOOOOO0KKXXXklllkXXXKK0OOOOOOOOOOOOOOKKXXXOoc,                     //
//                          .d00000OOOOOOOOOOOOOOO00000:   :00000OOOOOOOOOOOOOOO00000o.                       //
//                            .,0WN0OOOOOOOOOOOOOKWWd..     ..dWWKOOOOOOOOOOOOO0NWO,.                         //
//                             .,:o0XKOOOOOOOO0XXkc:.         ':ckXX0OOOOOOOOKX0o:,                           //
//                                '0MN0OOOOOOOKWMd               dMWKOOOOOOO0NM0'                             //
//                                '0MN0OOOOOOOKWMd               dMWKOOOOOOO0NM0'                             //
//                             .cdONMN0OOOOOOOKWMKxd,         ;dxKMWKOOOOOOO0NMNkdc.                          //
//                           .,c0NNNNXOOOOOOOOKNNNNNx,'.   .',xNNNNN0OOOOOOO0XNNNNO:,.                        //
//                          .OWX0OOOOOOOOOOOOOOOOOOOKNNc   lNNKOOOOOOOOOOOOOOOOOOO0XWk.                       //
//                           ';l0NNNNNNNNNNNNNNNNNNNx;;.   .;:kNNNNNNNNNNNNNNNNNNN0c;'                        //
//                             '0MMMMMMMMMMMMMMMMMMMo         dMMMMMMMMMMMMMMMMMMMO.                          //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PXMER is ERC1155Creator {
    constructor() ERC1155Creator() {}
}