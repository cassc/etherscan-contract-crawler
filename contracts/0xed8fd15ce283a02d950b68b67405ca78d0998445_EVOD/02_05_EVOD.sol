// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EVO Droids
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                 .,cldddoc,.                                    ..';:clodxkkkOOOOOkkxxdolc;,..                                                                //
//               ,dKWMMMMMMMWKd,                            .,:oxOKXNWMMMMMMMMMMMMMMMMMMMMMMWWNK0xoc;..                                                         //
//             .xNNKKNMMMMMMMMMXl.                     .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xo;.                                                     //
//            'OW0:,,cKOdO0okWMMNl                 .;lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOd:.                                                 //
//            dWWd.'',:;::,cddKMMO.             .cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl,.                                             //
//           .kMMNkoc,;c;;xX0kXMMO.          .ckXWMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMN0o,.                                          //
//           .dWMMM0lc:,oKkxNMMMWo        .:xXWMMMMMMMMMMMMMWKx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0xKMMMMMMMMMMMMMMMNOl.                                        //
//            ,0MMMXx:cxk0NNMMMNd.      'o0WMMMMMMMMMMMMMMMNx:dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd:xNMMMMMMMMMMMMMMMWXx;.                                     //
//             'xNMWOONXxOWMMWO:.     ,dXMMMMMMMMMMMMMMMMWKc.lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.cKWMMMMMMMMMMMMMMMMNO:.                                   //
//               ,oOXNWWWNXOd;.     ,xNMMMMMMMMMMMMMMMMMNx' cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc 'xNMMMMMMMMMMMMMMMMMW0c.                                 //
//                  .',;,'.       'dXMMMMMMMMMMMMMMMMMW0c. :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .c0WMMMMMMMMMMMMMMMMMWO:.                               //
//                              .lXMMMMMMMMMMMMMMMMMMNx,..;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;..,xNMMMMMMMMMMMMMMMMMMNk,                              //
//                             ;0WMMMMMMMMMMMMMMMMMW0c,:',OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,':,c0WMMMMMMMMMMMMMMMMMMXo.                            //
//                           .dNMMMMMMMMMMMMMMMMMMNd;lK0oOWMMMMMMMMMWNXXXXXXXXXXXXXXXXXXXXXXNWMMMMMMMMMWko0Kl;dNMMMMMMMMMMMMMMMMMMWO;                           //
//                          ,OWMMMMMMMMMMMMMMMMMW0:'oXNxdKWMMMMMMMMMXc'',;:;;:::::::::;;;,''cXMMMMMMMMMWXdxNXo':0WMMMMMMMMMMMMMMMMMMXl.                         //
//                         cKMMMMMMMMMMMMMMMMMMWx..,codolodxxk0XNWKo:;coddddxxxxxxxxddddddoc::oKWNX0kxxdolodoc,.'xWMMMMMMMMMMMMMMMMMMWx.                        //
//                       .oNMMMMMMMMMMMMMMMMMMMWKxoolc:;,,,,',;clo:  :xdxxkkONMMMMMMNOxkxxdx:  :olc;,',,,,;:clodxKWMMMMMMMMMMMMMMMMMMMWO,                       //
//                      .dNMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOxdlc:;;;:'  co,;:;::d0NMMN0d::;:;,oc  ':;,;:cldxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                      //
//                     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0O: .o0OOOOOOO0NMMN0OOOOOOO0l. :O0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                     //
//                    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'.l0KKKKKKKKKKKKKKKKKKKK0c.'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                    //
//                   .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNx;'..,:ccllllllllcc:'..';xNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                   //
//                   cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl..;dkOOOOOOOOkd;..lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.                  //
//                  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl',,:dOKNNKOd:,,'lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.                 //
//                 .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkod;.cOkkkkOc.;dokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                 //
//                 cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo..lNMMMMNl..dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                //
//                'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0KNWMMMMMMMMWNNNWWMMM0, .;okko;. ,0MMMWNNNNWMMMMMMMMWNK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                //
//                lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.,:cdOKNWMNOc:c;cKMMMMk..'....'..kMMMMKc;c;cONMWNKOdl:'.cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'               //
//               .OMMMMMMMMMMMMMMMMMMMMMMMXOxONMMWO;'lOkoc:;;cdo:..:.'0MMMMk'lX0kk0Xl'kMMMM0'.:..:odc;;;cokOl';OWMMNOxOXMMMMMMMMMMMMMMMMMMMMMMMNl               //
//               :XMMMMMMMMMMMMMMMMMMMWXkl'';lKMNx,,xNMMMWNKkdc;c:,:.,0MWNNx.:OOOOOO:.xNNWM0,.:,:c;cdkKNWMMMNx,,xNMKl;''lkKNMMMMMMMMMMMMMMMMMMMMk.              //
//              .dWMMMMMMMMMMMMMMMMN0xloc. ;dc:c:':0WMMMMMMMMMWXkodl.,KKc''...;::::;'..''cKK,.ldokXWMMMMMMMMMW0:';l:cd; .colx0NMMMMMMMMMMMMMMMMMK;              //
//              .OMMMMMMMMMMMMMMMMMXl;ldc. :xdxolxXMMMMMMMWWNOcloc:,.,d:  .;c;,,,,,,;:;.  cd,.,:colcONWWMMMMMMMXxloxdx: .cdl;lXMMMMMMMMMMMMMMMMMNl              //
//              ,KMMMMMMMMMMMMMMMMMWO:..   :xOX0kkKWWWMMWXx::,;:;;:ccllc,.,dd:'....':dd,.,cllcc:;;:;,::xXWMMWWWKkk0XOx:   ..:0MMMMMMMMMMMMMMMMMMMx.             //
//              :NMMMMNNWMMMMMMMMMMMXc     ,:ool:.;oddddl,,ld:;c;..,,,:c:''coox0XX0dooc'':c:,,,..;c;:dl,,lddddo;.:loo:,     cXMMMMMMMMMMMMNNMMMMMO.             //
//              lNMMMMXOKNWMMMMMMMWKc',.....,oc...,:cclc,.'od,.   .'.'colcolclo0MM0ol:locloc'.'.   .,dd'.,:lcc:,...co,.....,'cKMMMMMMMMWNK0XMMMMM0'             //
//              oWMMMMXo::lk0NMMMWO:coc:'.. 'Ok. .cxxxxdl,,od;...'''''....:odxxKWWKxxdo:....'''''...;do,;ldxxxxc. .kO' ..':coc:OWMMMN0kl::oXMMMMMK,             //
//              oWMMMMKc.  .'lXMNd'lXW0do:...ckdoONMMMMMWNOkko,.,;:clolc, ,k0xccllccx0k, ,clllc:;,.,okkONWMMMMMNOodkc...:dd0WXl'dNMXl'.  .cKMMMMMK,             //
//              lWMMMMXl. ';::oOc.;OWMNd:oc..cxldXMMMMMMMMMMMXo,'...''''. .ll:.    .:ll. .''''...',oXMMMMMMMMMMMXdlxc..co:oNMNO;.cOo::;' .lXMMMMM0'             //
//              cNMMMMO' ,dxoc,. .ck0Kd;codl.'xddNMMMMMMMMMMMXd:,:c:c:;;'.,co:,;;;;,:oc,.';;:::c:,:dXMMMMMMMMMMMNddx'.ldoc;dK0kc. .,cokd, 'OWMMMM0'             //
//              :XMMMWkl,.dkxl.....lddldKo'lo'':dNMMMMMMMMMMMWKOc..',:clloO0OodkkOOdoO0Ooclc:,'..cOKWMMMMMMMMMMMNx:''ol'oKdlddl.....lxko.,lkWMMMMk.             //
//              '0MMMMKoooOXOxc.....l0ddNO;.lo'.dWMMMMMMMMMMMMMXd'..  ..,coxdok0000kodxoc,..  ..'dXMMMMMMMMMMMMMWd.'ol.;ONdd0l.....cxOXkoooKMMMMWd.             //
//              .kMMMMNl'coxOx:...  ,d;;0WXOkxxONMMMMMMMMMMMMW0llc;. .';:,...oNNNNNNo...,:;'. .;cll0WMMMMMMMMMMMMNOxxkOXM0;;d,  ...:xOxoc'lNMMMMNc              //
//               oWMMMMKlcoccoco:..  ,dlxWMMMMMMMMMMMMMMMMMMWO;,;,coc,.:xxOkxKMMMMMMKxkOxx:.,coc,;,;OWMMMMMMMMMMMMMMWMMMWxld,  ..:ococcoclKMMMMMK,              //
//               ;KMMMMMW0xd:.,oxooc. :xxKMMMMMMMMMMMMMMMMMMWx,..,dNWd..oxOXWMMMMMMMMWXOxo..dWNd,..,xWMMMMMMMMMMMMMMMMMMKxx: .cooxo,.:dx0WMMMMMMx.              //
//               .xMMMMMMMKxd:.,oolxc  :okWMMMMMMMMMMMMMMMMMKc':l:,:xOo;,...;okXWWXko;...,;oOd;,:l;'cKMMMMMMMMMMMMMMMMMWko:  cxloo,.:dxKMMMMMMMNc               //
//                :XMMMMMMMKxd:.'',ok: .;oXMMMMMMMMMMMMMMMMMk.'ccodl;,ck0kl'. .;oo;. .'ok0kc,;ldocc'.kMMMMMMMMMMMMMMMMMXo;. :xo,''.:dxKMMMMMMMMO.               //
//                .xWMMMMMMMKxd:. ;xkxccl;kMMMMMMMMMMMMMMMMM0''dl',oxd:';oxl:ldc::cdl:lxo;':dxo,'ld''0MMMMMMMMMMMMMMMMMk;llcxkx; .;dxKMMMMMMMMNc                //
//                 ;KMMMMMMMMKxo.  :kkkKKclNMMMMMMMMMMMMMMMMWx',dxkkodkl'..;kNMMMMMMNk;..'lkdokkxd,'kWMMMMMMMMMMMMMMMMNlcKKkkk:  'oxKMMMMMMMMWk.                //
//                  oNMMMMMMMMKc.  ;0KkOXxc0MMMMMMMMMMMMMMMMMNd..',,'':lx00KWMMMMMMMMWK00xl:'',,'..dNMMMMMMMMMMMMMMMMM0cxXOxK0;. .cKMMMMMMMMMK;                 //
//                  .kWMMMMMMMM0,..'xWKxxl,oNMMMMMMMMMMMMMMMNo.':;cdkOKNMMMMMMMMMMMMMMMMMMNKOkdc::'.oNMMMMMMMMMMMMMMMNo,lxxKWx,..,OWMMMMMMMMNl                  //
//                   ,0MMMMMMMMM0:..,kWKl;.;0MMMMMMMMMMMMMMMW0;'cdkNMMMWMMMMMMMMMMMMMMMMMWWMMMNkdc';OWMMMMMMMMMMMMMMM0;.;lKWk,..:0MMMMMMMMMWd.                  //
//                    ;KMMMMMMMMWXd,.,kWKdloKMMMMMMMMMMMMMMMMMXl'cxkO0koddkNMMMMMMMMMMNkxdok00kxc'lXMMMMMMMMMMMMMMMMMKoldKWk,.,dXMMMMMMMMMWk.                   //
//                     :XMMMMMMMMMWk,.,OWWNXWMMMMMMMMMMMMMMMMMMNd.,ol;,..,c0WMMMMMMMMW0c,..,;lo,.xNMMMMMMMMMMMMMMMMMMWNNWWO,.,kWMMMMMMMMMWO'                    //
//                      cXMMMMMMMMMWx,.:0MMMMMMMMMMMMMMMMMMMMWKOxc':c',ldl;lXMMMMMMMMXl;odl,'c:'cx0KWMMMMMMMMMMMMMMMMMMMM0:.,xWMMMMMMMMMWO'                     //
//                       :KMMMMMMMMMWd,c0MMMMMMMMMMMMMMMMMMMKocodxkOo;:clc.,0MMMMMMMM0,.clc:;oOkxdocoKMMMMMMMMMMMMMMMMMMM0c,dWMMMMMMMMMWk'                      //
//                        ;0WMMMMMMMMNdlKMMMMMMMMMMMMMMMWN0Oo:oxOx:..,dOXO''0MMMMMMMM0''OXOd,..:xOxo:oO0NWMMMMMMMMMMMMMMMKldNMMMMMMMMMWx.                       //
//                         'kWMMMMMMMMWKNMMMMMMMMMMMMWKko;,colool,..'lxkkl.'OMMMMMMMMO'.lkkxl'..,cooloc,;okKWMMMMMMMMMMMMNKWMMMMMMMMMNo.                        //
//                          .oXMMMMMMMMMMMMMMMMMMWX0xo;...,;;,...,lxKOldd:,oXMMMMMMMMXo,:ddlOKxl,...,;;'...:ox0XWMMMMMMMMMMMMMMMMMMW0:                          //
//                            ;OWMMMMMMMMMMMMMN0d:,.';,...';'. .':lcc:,''.cXMMMMMMMMMMXc.,',:cll:,. .';'...,;'.':d0NMMMMMMMMMMMMMMNx.                           //
//                             .oXMMMMMMMMMMMXkl::::::::::ccccccccccccccclkWMMMMMMMMMMWklcccccccccccccc:::::::::::lkNMMMMMMMMMMMW0:.                            //
//                               'xNMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.                              //
//                                 ;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx'                                //
//                                  .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx,                                  //
//                                    .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd'                                    //
//                                       'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.                                      //
//                                         .:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                                        //
//                                            .ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.                                           //
//                                               .:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOo;.                                              //
//                                                  .'cd0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOd:'                                                  //
//                                                      ..;lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXOxl;.              ...............................         //
//                                                            .,:ldkOKXNWWMMMMMMMMMMMMMMMWWNXKOxdl:'.                  ,:',;;;;;;;;;;;;;;;;;;;;;;;;;'::         //
//                                                                   ..',;:cclllllllllcc:;,'..                        .:..dOxddxkOkolokOkxdlokkdodOo.':.        //
//                                                                                                                    ';.;XXxddlkNkcclONXko:lKXo:oXk..:.        //
//                                                                                                                    ;, lNWNX0xOWXxo0NWMNOkKNW0d0Wx..:.        //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EVOD is ERC1155Creator {
    constructor() ERC1155Creator() {}
}