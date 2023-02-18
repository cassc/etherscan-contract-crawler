// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Damian Peralta Artwork
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//                                            .    ..                           //
//                              ....   ....  .;,  .,'   .;.   ..                //
//                             .;lo;  .loo, .,llc'.;,..'cl'  'c,.               //
//                        .''. .lxxdloOOOOOoodclO0koloddoddc;:o,                //
//                    .,'..:dllOKOOOKXxdxod0KkxxkK0xdoddxk0kc,c:.               //
//                    .oxccxxkO0KKKKXX0kxoxOkxdxookkdllddxxllxk:                //
//                .::;okxxkOkOXXKkdddoxkxdkkkkddoldOkdodxxxocxOxoolc;.          //
//             .,';xxdOOO00kddOxclxOkdccxOOkkxxddxol;'.':oxxxdodxxloxk:         //
//             .cxOK0O0OOOkxdkxcdKKKKOkod0kxddddkx::c;:lclO0kkOkoccdkkx'        //
//           ..:xOOO00kkxxOOOOxddc:xxclk0KkxkOk0O:;cl0x';:l0k:;;l:..;Ok'        //
//        .,lxk00kxOkdkkxxd:,;coOd:dockk:',cc;:xOdkOO0ddOxxkc;;.'l.  cl.        //
//      .;d00dc,';xKkdOXkc:c:,;:lx:cc;xc';dk:cxddxo:xkoxdodkkko'cxdc;o:         //
//      c00O:.  .ol'.,kk'.';xl;ccxxlloOklclxOdxdcddlllcldkOxodkOx;,k0l.         //
//      l00o';c:xk''olxOodxkOdxOcoklllxOocx0kolxx:'. ....'lxdod0Kocd;           //
//      .d00x:'.:Oxdkxoddc:oddxkkdl,;xOOOO0doxxd,,ldxkOkxl,lOdokxd0l            //
//       .lXd.,xO0o:codkOkddxkkdlo0Odxxd0X0xxkxokXWWWWWWWNolOdxOlo0O'           //
//         ;xllKOoccddl:,'...,:oxodXKxoo0X0dx0klkKNWWWNKOdoOxokolkOOo.          //
//         .xO0Kd:okc,;oxkOkkkxllxxx0kddkKKOkKOllodoodxdoxOOxxdokK:,x:          //
//         cKodkllxlc0NWWWWWWWXkxOkdkOxxkOK00XkloddoodxkxkkclllkOdooOx.         //
//        .d0cxOddxxxOXWWWWNKkxxxxKKk0OdxO00x00xkxolloxO00klldx0xloclk;         //
//         dOcoKOoc;lddxkxxxoldkkkO0kOkodxOOokKdlc:::cc:oOxxO0Odx0x,'xc         //
//         ;Odlx0Oxod0X0OkxxxdxkdkkxxkxdkOO0kxkkkxxoloddkXkcx0kxdloxxOd.        //
//         .kxcldxxxOkkkOOkxdlodxO00Oxkxl:cdkkxkxx00dkkld0: :0k; ,dc.od.        //
//         .kW0xxdddxooxOOxxoccxOxddkOxc'.,oxdldKXOkkKklk0lcOOdo;:o:.dd.        //
//         .dOk000OKXXKxl:o0x::dOloOolcoO0Kk:ll,d00NNxcd0koOKKklkxloo0d.        //
//         .dl.l0OxocO0, .:O0xclxdxk;::.,:;,cc;:dOXWXdd0doKKoxX00o. ,Ol         //
//          ox:kXOOxcoOdcdockkdOdcdOc..,,;;;;;:ccokXWWWKdooOKOKXO; .xK;         //
//          lxckKo;kd;kNKkloKOcdKOkkdc:;;::cc:cclodxxkXNXO;dOokocdld0k'         //
//          :koollxkkkKx:xx,oNNXNNOol;,lxdxkdoxOkO0kldXk;dOkkK0ocOXOo:.         //
//          .kd.:Okdokx'lo;dKNWWN0dloloddooddooxO0dc:cxOOOolxxdc:do:o;          //
//           :kllx:cdOOdOOxOXNW0ooxkxllcccclolloc;,lkxxdlk0OlckOlolco'          //
//           .dO, .ol:OOcxOdok0Oxl:ccllcclccc;,.'oOkk0koxkdodxkd:'cOc           //
//            .oo.'do:xOc;ddddcd0ococ;,'....';odcoKKxkkkxdk0Ox:'clxo.           //
//             .lkOk:.;o;dOc,ldolcldox0kl;:cllkX0doxxxxOKxl;,cc.cKd.            //
//              .c0xlld0klodlxkccdl::dKx,.;lold00oxdlkdol::,.:ocd:.             //
//                ,odo:oklcx0kxxxxdoxOKOlccccclooo0koc',,;,.;xkl'               //
//                 .,llod,':ccoxkxkkddko;,....,'.:0X0l;. ,:,co,                 //
//                   .;ooloo;.;l,cOxxk:,,'',;,':,.okdcc:.,lc,.                  //
//                      'cxkoll:.,ld0o','.:::c;c,,lll',l:;.                     //
//                        .,lkkdodo:cd:,;,::,,::',;od;;,.                       //
//                            .;:ccloO0dlol:,,,;::::.                           //
//                                  ..';;;,',,',,.                              //
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract DeMian is ERC1155Creator {
    constructor() ERC1155Creator("Damian Peralta Artwork", "DeMian") {}
}