// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HENRY CHEN ARTWORK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                      ...'''';;;c;:,:d::;;;,'.'.,.....                                                                 //
//                                                  ...,.':'lllo:olc:ldodcl;cOcllllcc::coc::lc;:,'.....                                                  //
//                                          ...;,cl,dl;d;ck:xxdxcdol:cdodcc;lOcclloccccldcclooldllllllc;::;...                                           //
//                                     .,'l:cockdkO:xo;d;ck:dxdkcddo:coldol;o0c:cloc::cldlclooodcllllol:lddlooc:;'..                                     //
//                               ...'c.:Ocxxlockdx0ckd;d;:x:dxdx:ooo::oldll;l0lcccoc:;cldlllooldcllllol:lddoooolocllc;.'.                                //
//                            .,':O:;k;;kcdxlockdx0lkx;d:;xcdxdkldoo:coldll;lOllllllccclxlclolloclllclc:lxddolold:lldo:d;;,..                            //
//                        ..,o:kd:Ol,xc,klodcdlxdd0cxx;d:;xcdkxkldooccoldll;lOcllclllllldccllclo:cllclc:lxdoololo:cldlcd;oc;d,,'                         //
//                     .',xl:Olxk:Ox,dl'xoldcdcddo0ldk;xl,dcxOxkldlolcololl;lkcllclllccloccllccl:ccllc::oxoolcoldccloclo,o::d:ddc;.                      //
//                   ''lk:xd:OooO:xk,oo.ddldco:oxo0loO:xo;dcdkxkldlollococl;lkclocccc::ldccolccoclcoolccddoolclldllolcll;d;lo:xodl:c..                   //
//                .';xlckcok:xdlOcoO;ld.oxldcocoxoOco0cdd;dcokdxcolol:lcocc;cx:loll:c:cldlcolccolllollccdollllllolldl:occd;olcxox:od:o,.                 //
//              .,:dldd:klckcxdc0lcO;:x,cxldloclxlOll0cod;dcokdxcdloc:l:lcc;cx:clllcc;cldlcolccolololcccxolcoollllloc:o:lo;dcldod:dlld:o;                //
//              .doddoxckd:klokcOd:Oc;k;:xldloccxlOdl0cox;dllxdxldllc:l:ccc,:d:clcc:c;clolcocccoloooollldcc:lolollloccd:ol:dcdddocd:olcd:l;              //
//               ldoxlxcdx:xdoOlkk;xo,x:;xldooocklkdcOlok;oolxdxcoclc:l:ccc,:x::cc:::,lloccdlcclldoooclldcc:loldloooclo:dcco:xdxcco:dclo:x;              //
//               ;xododolk:dxlOodk,od'oc;xloooo:klxkl0llk:oolxxxloclc:l:ccc;ck::lll::;llolcdlccllddllclldllcloldlooolol:x:llcxddcolld:dllx.              //
//               .dddoodlOllklxdoO;lx'lc,xloooo:xldklOolk:oocxkkldcll:l:ccc;lkcclclcc,lllccoll:clooll:oodllclocollooooccd:dclxddcdcdlcd:do               //
//                cxxddxlkdckldxoOcck,co,dololl;dodkckdlkcoo:dkOldlol;l:ccc,ckcclclcl;llllco:c:clolll:ololcllocolooolo:locd:oddolocx:od:k:               //
//                'xkdoxodkcxooklkl;k::o,ddodll;oookcxock:oo:dxkodool;l::::,:k::lclll;lodlco:c:cooolo:oclcclcl:llldloo:ollocxdocolod:xllx.               //
//                .okkdxooOlddckoxo,xc,o;ddldlo:oooOcddck:lo:odkodoll;oc:cc,:k::cclcc,coxlcdcc:cooooo:dllcclcl:clldloo:oclllxoococdolk:do                //
//                 ;kkdoxlkoox:xddd,do'o:locdlo:ldoOcdd:xclo:odklooll;occcc;ckc:ccl::':odc:d:::lolooo:olll:occ;clldcolcococdddolllkcod:x;                //
//                 .dOdoxoxdcxlddok;od'l::dcdlo:cdoOlod:kccd:loklloll:occcc;ckc:lcl::,:odccx:::lollcl:olllcoccccoodclclllolxddolcdd:xlld.                //
//                  ckxlddokcdooxoOclx':c:dcdllccdo0ood:kllxcooxlllco:occc:;cOlclcl:c;:odclkcc:locccc;oollcocclclloclclllloxddolcxccxcdc                 //
//                  ;xkolxoklldoxokock;;l:dclllccxlOxdxlkllkcooxooococlccc:;cOlclcc:c,:dxlcxc::locccl;llllcllll:lllclclllloddoolok:oocd'                 //
//                  .dkdlddxdcxdxodx:kc;o:ocooolcxlkkdklklcOlodxdoocdcolcc:;cOlllcc;:,:dxlcdc:;colcco:lololooll:llclccclcloddoocddcxcol                  //
//                   ckkoodoxcddddlkcdd;ocooodolcxokkdklxlcOloodooococdolc;,:xcclll;:,:dxccxlc;cocccl:loldoodldlodcc:ccc:ldooolcxcodld'                  //
//                   ,xOdcooxoldodcxlok:oodooxoo:xoxkokoxlc0lodxoldcoldollc;;d:cdol;:;cdxllxlc;coclclclololodlooodllccl::loooolod:dlol                   //
//                   .oOklloodlxoxldxlklddoolxdocddxOokoxoc0oodxdldcoloollc::x::ool;:;cxxllklc;cdllclccoldooxlddodllllolllllodlxllold'                   //
//                    ,kOdldodoxxkdoklxooxxkxOOOk000X0KO00kXOO00OkOxkdxdolccck::ooollcdO0kkKkxxk0OkkOkxOkOkkOkkkxxolocdoooolooodcocl:                    //
//                    .oOkodddddkxxokO0XKNWWWMMMMMMMMMMMMMMMMMMMMMMWWWWNXK0kxKOOXXXXNNWMMWMMMMMMMMMMMMMMMMMWWWWNNXKOOddddkoooldllolo.                    //
//                     'xOxdxxxdk0KXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXK0kddodololo,                     //
//                      cO0xxxxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0xdxooooc                      //
//                      .d0OdxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOddddl.                      //
//                       'x0O0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOdxd.                       //
//                        ,kKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKkx,                        //
//                         ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,                         //
//                         .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                          //
//                         .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                         //
//                         .kMMMMMMMMMMMMMWNNK0OkkO00000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXK0OOkkkOOKXNWWMMMMMMMMMMMMd.                         //
//                         .kMMMMMMMMMNk;                  .ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMNX0Ok                YoOKNMMMMMMMMWd                          //
//                         .OMMMMMMWx     moXcoddddxxl:cc:;    lxO0NMMMMMMMMMMMMMMMMMMMNK0ko     ::clodxdddddolc    .xKWMMMMMWd                          //
//                         .OMMMMW.   cdkOKXXNWWMWWMWNXXKOdoc:    :okXWMMMMMMMMMMMMMWNOo:    cldxOKXNWWMMWWWWWNXK0kd   dKWMMMMd.                         //
//                         .OMMM.  jkKNWMMMMMMWNWMWXNMMWWMWWX0xc;   :o0WMMMMMMMMMMMMXo:    lk0NWMMWWMMNXWMMWWMMMMMMWWXOd .XMMMx.                         //
//                         .OMM od0NMMMMXkxXMXc dNO;;OWk .NX .XXOdl  lOWMMMMMMMMMMMM0l  :lkXXxdXNd:xW0;,OWk;lXW0kXMMMMMWXk NMMx.                         //
//                         '0MMNKWMMWNXW0' ,ONo  dKl  O0, o0c :KMWNXXXWMMMMMMMMMMMMMWXK00XN0; :Kx..kK; ;KO' lXk  xWNXWMMMWWWMMx.                         //
//                         '0MMMMMMM0 'dXk. 'OK: .dO; 'dc  cd. ,0WWWWWMMMMMMMMMMMMMMMWWWWNk' .ld. ,x: .d0: :XO' cKO;'dWMMMMMMMx.                         //
//                         '0MMMNOkXXc. lXO'   '                'OWWX0XWMMMMMMMMMMMWKKNWNx.                    ;Kk. ,0NKKWMMMMx.                         //
//                         '0MMMk. ;0Nd.          ........       'OWXko0WMMMMMMMMMNkxKNNd.        ........         ;0Kl  OMMMMx.                         //
//                         '0MMMNo. 'dd'      .:dOKXNWWNXKkl,     ,0Xx:;kWMMMMMMMNd;oOXx.     'cxOKXNNNNX0kl,.          cXMMMMx.                         //
//                         '0MMMMNo.        .oKWWKOkxddxk0NMNk:.   cKd..'OMMMMMMWk..'dk'   .ckNWN0kxxxdxkKNMNOc.       cXMMMMWd                          //
//                  ....   .OMMMMMNX      .lKWWOloxO000OxllkNMWO,  .xk'  :XMMMMMK; .c0l  .:0WMNkoodkO0kxoldOWMWO;     ;KMMMMMWo    ....                  //
//               .;x0KX0x:..OMMMMMMN.    ,OWMNd:dKKkoldOX0l,oXMMXl. :Ko. .xMMMMMk. 'OK; .dNMMXdlxK0dlclxK0d:xNMMNo.   OMMMMMMWo..ck0XK0x:.               //
//              .x0OkOKNMWx;xMMMMMMMN.  ,0MMMk:dX0:    .lKKo;xWMMNl '0K,  lWMMMMk. :XK, lNMMWxckXO´     c00o:OMMMNl  dWMMMMMMWo;OWMN0xdx0k'              //
//             .dd'.'lxOKNNoxWMMMMMMMK  .kWMWd;xXx  oo  'kXx;oNMMNc ,0k.  oWMMMM0' .kXc :XMMNdl0Nd  oo   OKd:xWMMK; cNMMMMMMMNdxWNOxdc'..ox'             //
//             od..lKWNOldKdoNMMMMMMMMK  'kWM0cl0Ko    'dKKo:kMMWx  oO;  ,0MMMMMWo. ;0O  dWMWOcxKKo    ,dKOlc0MMX: ,KMMMMMMMMNdkXocxXWNd..lo             //
//             kl.cNWO:. .ddlXMMMMMMMMMK  .oNWO:ck00kxk00kcckWMNx  l0xc,,xWMMMMMMKc,:xXd  xNMNkclOKKOkO00xccOWMXc  OWMMMMMMMMXdkd.  .oXWx.;x             //
//             xo.dWX; .lodlc0MMMMMMMMMMXl  :0WKxllloolcccdKWW0:  dNN0d.xNMMMMMMMWO.o0NNx  c0WWKxoooooolclxKWWO,  OWMMMMMMMMM0lxdox; .xWK;:d             //
//             :x:dW0'.kWOkd:OMMMMMMMMMMMNx  .cONNKOkxxOKNWXx:  c0WWWX.kNMMMMMMMMMWO.0NWWKo  ;xXWNKOxxxOKNWNk:  cKMMMMMMMMMMMOckkOW0'.dWKllc             //
//              lddXX::XXx0k;kMMMMMMMMMMMMMXo   'ldkO00Oxo:  ,oKWMWWX.kNMMMMMMMMMMMW0.KNWWWXd;  ;oxO000Oxdc'  cOWMMMMMMMMMMMMx:0KxKK;;KWkll.             //
//              .lxkXOdKOkNk,dMMMMMMMMMMMMMMMNOo,.        .x0NMMMMWX.xNMMMMMMMMMMMMMW0.0NWWWMWM...        ..kXWMMMMMMMMMMMMMWl;KWOkkl0WOdl.              //
//               .dOOX0kkxKk'oWMMMMMMMMMMMMMMMMMWNXKK0KXNWMMMMMMMW.CONMMMMMMMMMMMMMMMMK.0WWWWMMMWNXK0OO0XNWMMMMMMMMMMMMMMMMMX;;K0xxkKXkxo.               //
//                .kKOK0kxxo.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX.XKMMMMMMMMMMMMMMMMMMMXO.NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.,dxO000k0x'                //
//                 ,0XOKNKkl.;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMC.0WMMMMMMMMMMMMMMMMMMMMMW0.KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo ,okNX0KNK;                 //
//                  ;KWNWXKx..OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.K0WMMMMMMMMMMMMMMMMMMMMMMMM0k.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK: ;0XWWWMNc                  //
//                   :XMMMMO'.oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.0KMMMMMMMMMMMMMMMMMMMMMMMMMNO.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..cXMMMMWx.                  //
//                   .xWMMMO' ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM 0WMWXOkk0XWMMMMMMNK00KNWMMK NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  cXMMMMK;                   //
//                    ;KWMWk' .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK Nk'    'dNMMMNd,     kW. NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.  ;0MMWKc                    //
//                     .cddc.  .dNMMMMMMMMMMMMMMMMMMMMMMMMWNNXKKKk xoc:;;:dXMMMXd:,;:cd0 O0KXXXXNWMMMMMMMMMMMMMMMMMMMMMMWx'.. .:ddc'                     //
//                         .. . .dNMMMMMMMMMMMMMMMMMMMWKkdl: ,,' '.'...ooddddddoooooo....'''', ,:ld0XWMMMMMMMMMMMMMMMMMWk,... .                          //
//                         . .....oXMMMMMMMMMMMMMMMWKxc'..   ..  ..    .    ..  ...    .  ...     ..;cxXWMMMMMMMMMMMMMNx'..  .                           //
//                         .  .   .:OWMMMMMMMMMMMWOl'.   . .   . .       ..   .. . .  ..      ..      .;dKWMMMMMMMMMW0l.... ..                           //
//                         .. ..   ..lKWMMMMMMMWKl  . ., .´ol.olo.oll.llccccc.clc:c:;::;;:clcc.cn. ' .  .,xNMMMMMMWKo'...  ...                           //
//                         . ..   .. .'o0WMMMMXx; . ..,dOkk0KKXXNNNNNNNNNNNNNNNNNNNXXXXKKKKK00Okdddl.   ...oXMMMNOo,. ....  ..                           //
//                         ..    ...   .'cdOKk:.  ..  PxX xXNNO.NNNNKO.NNNNX0,KNNNNN.0XNNNX,0NNKk NkO      .;dOx:....   ..  ..                           //
//                         .. ..  ...   .............  OE FEKER DMMM0k XMMMWO 0MMMMX OXMMMG CXNWH OD   .     ........ ..  ....                           //
//                         ...  . .....   ...... ..       ´vEW+ ´CXRTY O00Odc KK00ON ZUEPX´ +OPu´          .........  .... ...                           //
//                         ......  .....   ......  ..                   █         █                    ....  .......... ......                           //
//                          ... .. . ...  ...   ...... .               █ H E N R Y █              .  ... . ....  ..... ......                            //
//                          .... . ....   .. .  ......':x ,            █  C H E N  █              xcc:..  ..... ...  ....  ..                            //
//                           . .. ......  .....  . ...'co xOkc.         █  N F T  █           cxxd xdc..  ..... ....  .... ..                            //
//                           ...  .....     ..  ..  ...'lddONWK Ac,.     █████████     .;cD XWNkooo:.. ...... ....   ...  ..                             //
//                            ....  ...  ......     ... .:dkkOO GWWXkc cdk00k OK0kxo lkXWMV O0Okxl'... ......... ... ......                              //
//                             ..  ......  ..   ...  ....:dOOxk0KNXOKM MMWOo0 MMMMXK NK0kxO0kl,. ... ..     .  ... ... ...                               //
//                             . . .....    .......     ..  .,cxKK0KOxOKKKXKdcxKK000OkO00KK0xc'...    ...  ...   ... .....                               //
//                              .. ....    ..... .....    ..  ..,lx0KXKKK000OOOOO0KXXNXKkdc'......   ..  ....   .........                                //
//                                ....  ..  ...  .   ......    .....;:loodkkkkO0Okxdoc;'.........   ..... ......   .. ..                                 //
//                                 ... ...  .. .    .  ....  ...  ...........  ....... ......   .. ... ...    ....  ...                                  //
//                                  .. .. .   .. .......    .....  ... ...... ....  ......  .... ...  .....     ......                                   //
//                                   .. .... .. ...  ...   ....   ...  ... ..  ..... ......  ............ ....  .....                                    //
//                                     .... ...      ..   .   ...... .....  ........   .....  ........ ..  ..... ...                                     //
//                                      . ...   ... ..    ......... ..  ..  ... ..    .......  .......   .......  .                                      //
//                                         ......   .   ...  .......  ...   .   ....   ... . ..   .....  ....  ..                                        //
//                                           ......  ....  ....   ...  .. .... .     .  .... ...  .. .........                                           //
//                                             .....  .....      ...  ......   .   .  ..   ....    . ......                                              //
//                                                ....  ...  .. ....  ... ... ..   ......    .. .  ..  .                                                 //
//                                                   ....    . .....   ..  .......        ......   ..                                                    //
//                                                      .. ...   ...    .......   .....   .... .                                                         //
//                                                            .   .......     ...    ....                                                                //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                               ██   ██  ███████  ███   ██  ██████  ██    ██         ███████  ██   ██  ███████  ███   ██                                //
//                               ██   ██  ██       ████  ██  ██   ██  ██  ██          ██       ██   ██  ██       ████  ██                                //
//                               ███████  ███████  ██ ██ ██  ██████    ████           ██       ███████  ███████  ██ ██ ██                                //
//                               ██   ██  ██       ██  ████  ██   ██    ██            ██       ██   ██  ██       ██  ████                                //
//                               ██   ██  ███████  ██   ███  ██    ██   ██            ███████  ██   ██  ███████  ██   ███                                //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HCART is ERC721Creator {
    constructor() ERC721Creator("HENRY CHEN ARTWORK", "HCART") {}
}