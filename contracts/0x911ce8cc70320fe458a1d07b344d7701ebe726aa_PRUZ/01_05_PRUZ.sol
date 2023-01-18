// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fine art by Marlon Pruz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    NNNXXNNNKd,.,kKXKOOO0KXXNXKd'                                          ....                      ....                                ,ooc::dKWWWWWWWWWWWMMMMWWWWWWNKx:cxKXKx                                //
//    ;;cxOKXKOxl;;:ldOXNWWWWWNNNNNNXXXXNNKd,.c0X0x:'';clooc;.                 ...........                                       ....                                  ,dxd:.;ONWWWWWWWWWWWMMMWWWWWWWWXkdk0K0o    //
//    dlcccc:::::cdOKXNNWWWWWNNNNNNNXXXXXXOl;;oOOo,.    ...    ...          ..:lddddoooooll:;'..                               .....                                   ,okko,'o0NWWWWWWWWWWWWWWWWWWWWWWNNNNX0k    //
//    NNX0kdodxOKNNWWWWWWWNNNNNNNNNNNXNNXOl':x0Od,             ..         .;ok0KKKKK000KKKXXKOxl:,..                         ......                                    .;dOko,'cONWWWWWWWWWWWWWWWWWWWWWWWWWWNN    //
//    NWWNNNNNNWWWWWWWWWNNNNNNWWWWNNNNNXOl''oKKkc.                     .'lx00Oxo::::::::cd0XWWNXK0xc'                       .....                   .....';::::;,'..    .:k0ko''dKNWWWWWWWWWWWWWWWWWWWWWWWWWWM    //
//    OXNWWWWWWWWWWNNWWWWWNNWWWWWNNNNX0d:':k0Kkc.                    .,oOKKOl,.',;cclc:,.';d0NWWWWXOo.                                           .,cdxkkO0KKXXKK0Okdl:'. 'lkK0d;,c0NMMWWWWWWWMMWWNNNWWWWWWWWWW    //
//    lONWWWWWWWWWWWWWWWWWWWWWWWNNWNXOl,,oONXkc.                   .'lkKKOl'..:x0XXNNNXKkl,'lkKNWWWXk:.                                       ..:d0XNNXXXXXXXXXNNNNNX0xc. 'oKX0o''o0NWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    ;xKWWWWWWWWWWWWWWWWWWWWWWWWWNKx:,ckKXKk:.                   .ckKX0o'..lkKNWWWWWWWWWKxc,:xXWWWN0d:.                                    .;ok0XXX0kolc::::;:lxOXNWWXk:. :0NXOl.'o0WWWWWWWWWWWWWWWWWWWWWWMMM    //
//    ,ckXWWWWWWWWWWWWWWWWWWWWWNNKxc',o0XKkc'.                   'lONN0o'.:xKWWWWWWWWWWWMWXk;'l0NWWWXkl.                                  .;oOKK0xc;,'.';:::;;;,'':d0NNKd,.,xKNXk;.'dKNWMWWWWWWWWWWWWWWWWWWWWW    //
//    ',oONWWWWWWWWWWWWWWWWWWWX0d:''ckKX0o,.                    'o0XXO:',o0NWWWWWWWWWWWWWWN0l.;xKNWWKxc.  .                          .   'lOK0Oo;...;cok0KKKKK0ko;..;xXXOl'.cOXNXk:.,dKWWWWWWWWWWWWNWWWWWWWWWW    //
//    ollkKNWWWWWWWWWWWWWWWWXOo:',ckXNN0o'                     'lOXKx:.,dKNMMWNXKKXNWMWWWWNKd;,lONWN0o,.  .                            .:x0KOl'..:dk0KKXNNNNNNNNN0d,.c0XKx,..o0WWXx,.,kXWWNNNNWWWWWWWWWWWMMMMW    //
//    Kkld0NWWWWWWWWWWWWWNKxl;,;oOXWNKkc'                     .ckKXO;.,dKWMWN0xoccokXWWWWWNKx;,lONNXx;.                               'lkK0o,..cxKNNWWWNNNNNNNNNWNKx:cx00k:. ,xXWW0o..oKNWWNNNWWWWWWWWWWWWWWWW    //
//    ko;;d0NWWWWWWWWWNXOd;',cx0NNN0xc'.                      ,xKX0o'.o0WWN0xoodol;cOXWWWWN0o,,dKWNOl.                              .,o0KOl..;dKNWMWNXXNNWWWWWNNNNXOocoxOkl. .ckXWXk:':kXWWWWWWWWWWWWWWWWWWWWW    //
//    dl;,cxXWWWWWWWNKxc'.,lOXNNXOo;.                        .cONXkc,cOXNKxllxKX0xclONWWWNXO:.:kXNKx:.                             .:xKX0c..ckXWWWX0koodOXNWWWWWNNXOlldkOx:.  .:ONNXd,.:ONWWWWWWWWWWWWWWWWWWWW    //
//    KklclkXWWWWNKOo;'.,oOXNNKkl'.                          ,o0N0o;;xXNXkloONWXkookXWWWWN0o'.o0XXO:.                             .;xXX0o'.cONWWXOdooolclx0NWWWWWN0d;ck00x,    'o0NN0l..oKNWWWWWWWWWWWWWWWWMMW    //
//    kdlokXWMWXKkl,.,cxKNNXOd:.                     ....   .:xKNO:.:ONNKkdONMN0l:d0NMMWNKd,.:kXN0d'                             .;xKX0l..cONWWKkllxKX0dcd0NWWWWWXx;.:OK0d,    .,dKNNOl';xKWWWWWWWWWWWWWWMMMMM    //
//    lox0XNNKko:,,:oOXNNXkl'.                       ....   .lOXXk'.c0WNKkx0NWXkllkXWWMWXO:.;xXWXOl.                  ....       'd0K0d'.:kXWWXxlokXNKxodOXNWWWNXk:.,dKX0o'      ;kXWNk:.,kNWMMMWWWWWWWWWMMWWW    //
//    0XXXKko:,,;lkKNWNKkc'                          ...    .d0XXd..o0WWKkx0NW0xldKWWMWN0d,'o0NWXx:.                   ...      .:kXKd,.;xXWWXkooOXNKdco0XWWWWN0d;':xXWNOl.      .lONWKo'.oKNWMWWWWWWWWWWWMMMM    //
//    X0xl:,...ckXWWN0xc.              ...            ..    ,xKX0o';xXWWX0OKNNOookXWMWWKx;,cOXWN0l'      ......',;:cc::::::::;'';o0X0:..oKWMN0xdkXWKkod0NWWWWXOc..ckXWN0o,.       ,o0NXOl';xKWMWWWWWWWWWWWWMMM    //
//    c,.,cooc;lOXNKd;.               ....                 .:OXX0l,ckXWWWNNWWXkooONMMWN0c.;xXWWXkl,,;::clddxxxxkOKKXXXXXXXKXKKOkOKNNO, ,xNMMWX0KXWWKOk0NWMWWXk:',o0NWWKx;          :ONWXx,.:kNMWWWWWWWWWWWWWWW    //
//    ;:lkKXKx,,x00k;                ...                   .:ONX0l,ckXWMWWMMMNOdokXWMWXk:'lONMWNKOkO0KKKKKKKKKK00OOOOOOkkkOO0KKKXXNKx'.cONMWWWWWWWWNNNNWWMWKkc,:kKWWWKx:.          'xXWW0l..dXWMMWWWWWWWMMWWWW    //
//    KXXXXXXkc;okOx;                                      .cONXkc,lOXWWWWWMMWKklo0WMWKd,'oKWMWNNXK0Oxolllcccc::;,,;;;;;;;;;;;::ccc:'..ckXWWWWWWWWWWWWWWWWXkc;lkXWWNKx:.           .lONWXk:'l0NWMMWWWWWWWWWWWW    //
//    WWWNXXX0xoloxd:.                                 ....'l0NKx:;dKNWMWWWWMWN0xxKNMWKd,'o0XX0xolccc;;;;:::::::clddxxxxkxxdoc::;::;,'':dKNWWWWWWWWWWWWWWN0l':kXWWN0o;.             'l0NNKd;:xKWMWWWWWWWWWWWWM    //
//    WWWNXXXX0d::dkdc'                                ..'',l0NKxc;dKNWMWWWWWWWWNNWWMWXx;.,clc;,,;cdxO0KKXXXXXXNNNNNNNNNWWNNNNXXXXXX0kxxOXWWWWWWWWWWMWWMWXk:'l0NWXkc.                ,kXWNk:,l0NMWWWWWWWWWWWWW    //
//    WWWWNNNX0d,;d00k:                                .';:;cOXXOl,cOXWMWWWWWWWWMMMWWXOo,  .';cdOKNNWWWWWMMMWWWWWWWWWWWWWWWWMMWMMMMMWWWWWWMMMMWWWWWWWWWMWXx;.l0NXOc.                 .dKWNO:.;kNMMMWWWWWWWWWWW    //
//    NWWWWNNXKx:;dO0k:                                ..;:,;d0XXd'.o0WMMWWWWWWMMWWN0d;..':dOKXNWWMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMWNXK00KXNWWWWMWXOc':xKXOl'                 .lOXN0c.'xXWWWMMWWMWWWWWM    //
//    WWWWWNNXXOocoxkx:.                                .;;..:xKXk. ;kNWMMWWMMWMMWWXklclx0XNWMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNKxl:;;:lxKNWMMWWXk:''lOK0x;.               .,dKN0l.'dXWWWWWWWMMWWWWM    //
//    WWWWWWWWNKkocldxc'.                                ...'cx0Kd. .oKNWMWWMMMMMWWWNXXNWWWMMMMMWWWWWMMWWWWWWMMMWWWWWWWWWWWWWWWWWWWMMWWWXOo,':lc:',oONWWWWWN0o''ckKKOo'               'l0X0o..dXWWWWWWWWWWMMWW    //
//    WWWWWWWWNX0d;;ldo:.                                .,lxOOdc;'':xKNWMWWMMMMMWMMMMMMMMWWWWWNX00KXNWMMWWWWWWWMMMMMMMMWWWMMMWWWWMMMMMWKl',l0XX0o;;l0NWMWWWWKk:,ckXNKd,.             'l0NKd,.oKWWWWWWWWWMMMWX    //
//    WWWWWWNWWNKx,'cddl,                               ,oO0Od;',lk0KNWWMMWWWWWMMMMWWMMMWWWWMWXkl;',lxKNWMMWWWWWMMMWWWWWWWWWWWWWWWMMMMMWO;.;xXWWNKd;,dKWMWWWMWXkc,ckXNKx,             .c0XKd,.oXWMMWWWMWMMWXOo    //
//    WWWWWWWWWWXk;'cdxo,                             .cxOOd:',lOXWWWWWWWWWWWWWWWWWWWWWWWWWWWXx:;::;,,l0NWMMWWWMMWWWWWWWWWWWWWWWWWWWWMMW0:..o0XXKkc..lONMWWWWWWXk:'cOXNKd,.            ;OX0d''dXWMWWWWWWWWKd:;    //
//    WWWWWWWWWWN0l;lxkd;                           .cdkko;',oOXWWMMWWWWWWWMMMMWWWWWWWWWWWMWNOc'cOKKx;,lONWWWWWWWMWWWWWWWWMMMWWWWWWWWWWWKd,.,oxkx:. .ckXWMWWWWWNKo',o0NN0o'            ;OX0o''dXWWWWWWWWN0d::x    //
//    WWWWWWWWWWNKdcoxkx:.                        .;oOOd:';d0NWWMMWWMMMWWNNNWWWWWWWWWWWWWMMWKx;'oKWWXx:'l0XNWMMWWMMMMMWWNWWWMMMWWWWWWMMWN0o'.:dkkl'..cxXWMMWWWWWN0l;;dKNXOc.          .:OX0o..dXWMWWWWWWKd::xK    //
//    NWWWWWWWWWWXkoldkkl'.                      .:xkxc,,o0NWMMMMMWWWMMWNKxdxO0KKXNWWWWWWMMN0o:cxXNWX0o;:xOKNMMMMMMMWN0xddOXXNXXXNWWWMMMWNO:.;xKNX0dccdKWMMMWWWMWNOl':kXNKd;.         'l0X0l..dNMMMWMMMW0c':kX    //
//    WWWWWWWWWWWNOdccxOxc'                     ,dkko;'ckKNWWWWMMMMMMMMMW0o::clodkKNWMWWWMMNOocoxOkxk0OoclokXWMMWMMWXOl'.';;::;:cx0NWMMMMWKd;;oKWMNOl:o0NMMMWWWMMWXkc;lONNOl'         ,o0NOc.'xNMMMMMMMWKl,:xX    //
//    WWWWWWWWWWMWKd;;x00x;                   .cx00o;;o0NWWWWWMMMMMMMMMMWX0kkO000KNWWWWWWMMWKxlcoxl;lOOxl::dKWMMWMMWKk:';c:;;;,'.,xXWMMMMMN0d;;oOK0o;:dKWMMWWWWWWMWXx:,lKNKx;        .;dKNOc.,xNMMWNXK0KOo::xX    //
//    WWWWWWWWWWWWXx;;kKKkc.                 .l0KOl',xKWMMMMMMMMWWWWMMMMWWWWWWMMMWMMMMMMWWMWXkc,ckkxOK0kc''c0WMMWWMWN0o''cx0K0xc.,xXWMMMMMWN0l,',;::cxKNWMWWWWWWWWMN0l';kXN0o'       .ckXNOc':ONWN0dllllc,';dX    //
//    WWWWWWWWWWWWXk;;xKKOc.                'oOX0o,,oKWMWWWMMWWWWWWWMMWWWWWWWWWWWMMMMMMMWWMMN0l';x0XWWXkc..:ONMMMWMMWNk:.'lxkxl,:dKWMMWWWMMMNKko::lx0NWWWMWWWWWWWWMWXx:;o0NXkc.      .lOXXkc;l0NXxc;cxOko;.'o0    //
//    MMWWWWWWNWWWXk;,d0KOc.               .c0X0d;,o0NWWWWWWWWWWMMWWWWWWWWWWWWWWWWWWWWMMMMMMWNOl;;oKNWXk:..:ONWMMMMMMWX0dc:;'',ckXWMMWWWWWWMMWWNXXXNWWWWWWWWWWWWWWWWN0o;:dKXOo'      .o0XXk::dKN0c,ckNWWX0xc:o    //
//    WNNNNNWWWWMWXk;,dKKOc.              .ckXKd;'cONWMMMMMWWWWWWWWWWWWMWWWWWWWWWWWWWMMMMWWWMWN0l..;oxdc'.,l0NWMWWWWWWWWNKOdlokKNWWWWMMMWWWWWMMMMMMWWWWNK00XNWWWWWWWWXk:'c0X0x;      .xKNKd:ckKXOc:d0NWWWWN0dl    //
//    xolldk0XNWMWXx;,xKX0l.              :OKKx:,oONWMWWWWMWWWWWWWWWWWWWWWWWWWMMWWWWWMMWWWWWMMWN0d:'';;;cdk0NWMWWWWWWWMMMWWNXXNWWWWWWMMMMWWWWWWWWWWWWWN0dloOXWWWWWWWWN0l':OXXOc.     ,kXXOl,lOXKkcckKWWWWWWWNK    //
//    ;,,;;::oOXWWKd,,xKX0l.             .dKXkc,c0NWMMWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMWWWMMMMMWWWNKOkkO0XNNWWMWWWWWWWWWWWWWWX00KNWMWWWWWWWWWWWWWWWWWWWNOo;:xKWWWWNNWWWXx;:xKXKd,.   .:OXKd,.oKNXkcckXWMWWWWWWW    //
//    xOKKOd;,:xXNKd,;kXX0l.            ,oOK0oclkXWWWWWWWWMWWMMMWWMMMWWWWWMMMMMMMMMMMMMMMWWNNWWWWWWWWWWMMMMMWWWWWWWWWWWWMWN0d;,lONMMWWWWWWWWWWWWWWWWWWXkc;ckXWWWWWWWWWN0l:oOXXkc.  .;dKN0c..dXWNkc:xKWWWWWWWWW    //
//    NWWMWXOl,ckKKx;;kXXOc.           .c0K0d;:OXWWWWWWWWWWWWWWWMMMMMMMMMWWWMMMMMMMMWMMMWXOxx0XWWWWWWWWWWWWWWWWWWWWWWWWWMW0o,. .lOXWMMWWWWWWWWWWWWWMWN0l';dKNWWWWWWWWWWXxc:dKXOo'  .d0NNk;.,xNMW0c,ckNWWWWWWWW    //
//    WWWWMWXx,'okOd;:OXXkc.       .   .dKKkc'cKWMMMMMMWX0xxxkOKNNNNNWMMMWWWWWWWWWWWWMMMWKd,,lONWWWWWWWWWWWWWMMMMMWWWWWWWKd;,,'.';d0XWWMWWWWWMMWWWWNKkc.'l0NWMWWWWWWWMMNOc':0X0d;  'kXX0o,;dKWMWXx::dKWWWWWWWM    //
//    WWWWWWNO:,cdxo:l0XKk:.      .'..,oOXKd:cxXWMWWMMMWKd;.',:lodxOXWWWWWMMMWWWWWWWWWMWWXOc',dKNWWWWWWWWWWWWWWWWWWWWWWNOl,;oOOxc,,;lx0XNNNNNNNXX0kdc'.,o0NWWWWWWWWWWWMN0l';OX0x;  ;OXKx;.l0NWMWNKd:ckXWWWWWWN    //
//    WWWWWWN0l;codoclOK0x;       .'..cOXXkc:xKNMMWWWWWWN0xddxxolokKNWWWMMMMMMMWWWWWWWWWMWXk;.,dKNWWWWWWWWWWWWWWMWWWWN0d,.,dKWWNKkl;'.,:loooooolc:;;:lx0XNWNXXXNWWWWWWWN0o';OK0d,..c0XOl',xXWWWWWW0c,ckXWWWWNK    //
//    WWWWWWNOc;ldxdlokOd:.      .''..oKX0o':ONWMMWWWWWWWWNNNNNXXXWWMMMMMMWWMMMMMMMMWWWWMWWKx;.':x0XNNWWWWWWWWWWWNX0xo:,,lkXWWMMWWX0xl::::;;;;;:coxOKXNWWWNXKKXNWWWWWWMN0l';kKOo, .;oxl;;o0WWWWMWNO:..,lkXWWWX    //
//    WWWWMWNk,'lxxdooxd;.      ....':kXKxc,lKWWWWWWWWWWWWWWWWMMMWWMMMMMWWWWWWWMMMMMMWWWWWWWN0d:'';lodxxxxkkkkkkxo:,',:dOXWWWWWWWWWWNNXKKK0OOO0KXNNNNNXXK000KXWWWWWWWWN0o'.'oxo:'..,;;..'lOXWWWN0xl;'',:d0NWWW    //
//    WWWWMWKx;;oxxoccc:'       .. .:x0XOlcoONWWWWWWWWWWWNNNWWWWWWWWWWWWWWWMMWWWWWWMMMMWWWMMMWNKkoc::;;,,,;;;;;;,;;:okKXWWWWWWWWWWWWWWWNNNNXNNNNNNXXKK0000KXNWWWWWMWN0dl:,,;;'.,coxkkxl:,;:okK0kl;cxOO0KKKKXNW    //
//    WWWWN0dccokkl;,''..          .o0K0o,cONWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMWWWMMMMWWWNNXXKKK00OOkkxxxxxxxxk0KXNWWWWWWMWWWNWWWWWWWNNNNNNNNNNNXXXXXNNWWWWWWWWWMNOl';x0KOdclx0XNWWNNX0xl;:c:;;ckXWWWWN0doxK    //
//    WWWN0o'.;loc'...             .dXKkc,oKWWWWWWWWWNWWWMMMMMMMMMMMMMMMMMWWWWMMMWWWMWWNKOdollloooooxOKNWWWWWNNWWWWWWWMWMMWNKOxddxk0KNWWWWWWWWWWWWWWWWWWWWWWWWWWWMWKx:,lKWWWNXNNWWWWWWWWWNXOl.  ,oONMWWWN0o;,l    //
//    WWWKd;.  .;:;;,'..          'cOX0dclkNWWWWWMMWWWWWWWWMMMMMMMWWWWMMMMMWWWWWMMMMWXOd:,,:codxdoc:,,lOXWMMMMMMMMWWWWWWNN0xc,,;::::ld0NWMMWWWWWWWWWWWMWWWWWWWWNNX0xc:lOXWWWMMMMMWWWWWWWWWWN0l. .cOXWWWWWNKxc;    //
//    MWXk:..',lk0XXKOxo;..      .ckKKkccd0NMWWWWWMMMMWWWWWWWMMMMMWWWMMWWWWWWWWWWMMWXkc,;oOKXNNNNNXKxc,,o0XNWMMWWWWWXKkdol,.,lkKK0Odc,:xKWMMWMMMWWWWWWWWMMWNX0xollc'.,d0NWMWWNNNWWWWWWWWWWWWNKx:.':dKNWWWWWNKk    //
//    MNKd,,oOKNNWMMWWWNKOo,.    .o0K0o,cONWWWWWWWMMMMWWWWMMMMMWMMMMWNXKOkkkxxxk0XNKxc:oONWWMWWMMMMWNKx:,:lxXWWMMWN0dc:;,,';d0NWMWWN0dc:dKWWWWWWMMMWWWWWWWXOo:;;:loc;ckKNWMWX0xoxKNWMWWWWWWWWWNKkl:lONWWWWMMWN    //
//    WN0l.,dKWMMWMMWMMMMNKx;.   .dKKkc,lKWMMWWWWWMWWWWWWWWMMWWMMMWN0xc;:;;;;;;:cloc,,o0NWMWWWWWWWMMMWNOo,':xKWMMNOl,;d0KKKKNWWWWWWMWXx::x0K0OOKNNWWWWWWWXkc,cx0XNNXKXNNWWWWX0o'.cONWWWWWWMWWWWWNXXXNWWWWWWWWW    //
//    MWKx:ckKWMWNXXXNWWMMNKx;.  ,xK0xc;o0XNNNWWWMWWWWWWWWWMWWMMWNKx:',cxkOOO0Oko:'..:kXWMMWWMMMMMWWWMMWKdc:ckXWMXx:;dKWMMMMMMWWWWWWWN0c'';clccclx0XWWWWNkc:lONWMMMWWWWWWWWWWNKx:;oOXWWWWWWWWWMMMMMWWWNKOOKNWW    //
//    MWWNXXNWMWN0olxKNMMMWNOo'..cdxd:'.,cllodk0KNWWWWWWWWWWWWMMN0l',lOXWWWWWWWWX0d;';xKWMMWMMMMMMWWWWMMNkdc'c0NNKo:lONWMMMMMMMMMWWMWW0:. ,lxkko:',o0XWWKx:cxXWMWWWWWWNK00KNWMWXxc:dKWMWWWWWWWWWMWWWWWXklcdKNX    //
//    WWWWMMWMMWXk;'o0NWMMMWKx:...,;;,',:cc:;,'':oOXWMMMMMWWMMMWXx''o0WMMMMMMMMMMWXOc';o0NWWMWWMMWWMWWWMN0xl''lxkd:;o0NWWNNNWWMMMMMMMWKo,:xKNWNXO:..;lxkkdllxKWMWWWWWN0d;:xKNMMNk:'cONWWWWWWWWWWWWWWWWXkl;:oo:    //
//    WWWWWWMWWXkl;cOXNXXXWWXk:. .:ok0KKXXXK0kl;..;oONWMWWWWMMMN0o;cONWMWWNXXNWWMMMN0d::xXWMWNXXXNWMMWMMN0kd'..;;'.'o0NWKxodKWMWWMMMMWNXKKXWMMWWKo'...,;;,;:d0NWWWWWMNk:.;kXWWN0o'.'lkKXXK0KXWWWWWWWWWNOo,..,,    //
//    WWWWWMWN0d;,lkXNKOk0NWKx;'ckKNWWWWWWWWWWNKkl'.;xKWMMMWMMWXkl:dKNMMWKxlclx0XNWWWNXKXNWMNKd:o0NWMWMMNOxl''okko;'ckXNO:.,kNMMMWWWWWWWWWWWWWWN0l';oxxl. .,oONWMMWMMXkc'c0NNXkl;,,;,,:lc:,;oOXWWMWWWMN0d;,lk0    //
//    WWWWWNKk:''lOXWWNXXNNNOo:lONMMMWWWWWWWWMMMWXkc',oKWMMWWMWXkc:dKNMMWXOo;,;:clox0NWMMWMWXk:.,xKWMMWWKdc::dKWWXx;'c0N0o',dXWWNXOkOXWMMMWWWWWNKdlxKNN0o'.,o0NWWWWWMN0o,,oxdl;;ldoc;'.,:::;,;lOXNWWWWXklco0WW    //
//    dxxxdl;'':xKNWWNXKKXX0d:lOXWMMWWWWWWWWWMMMMMN0d;:xXWMWWWWNKd;:xKNWWWNNX0Oxl;'':oOXNX0xl,..:xKWMMWKx:';o0NMMNO:.;ONN0o,,lxkd:''l0NWMWWWWMWWNXXNWWWWKkdx0XWMWWWWMWN0o;'';lxOOx:;dO00KXXKx:',:oxxdol:cd0NWW    //
//    ;;'..  .:kXWMWN0dlxO0kc,o0NMMWXKKXNWMWWWWWWMMN0o:lOXWWWWWWXx,..;coxOKXXXNNXKOdc;;:ll:,,'..:x0NMMWKxc:lOXWMMNKxoxKWWNOl'.';;'..cOXWMWWWMMMMMWWWWWWWWNNNNWWWWWMWWWWN0o''o0NNOc.;kNWMWMMWNKd:',,,'';okXNWWW    //
//    Ox:,..':d0NMMWNKkk0XKk:'oKNMWXkdx0NWWXOxkXWMMWXd:ckXWMWWN0d:..,;::;;;;;oOXWMWN0d,..:oxO0kl:;lkXWWWXKKXNNNXXNNNNNNWMWNOl,;okOd:ckXWMWWWWWWWMMWWWWWMMMMWWWWWWWMWWWMWNOlcxKNKd::dKWMMWWWMMWNXK00OOO0XNWWWNW    //
//    NOl;:::ld0NMMWWWWWWWXOl:xXWMWNK0KXWWKd::dKWMMWKd:lkXWMWXOl,;lkKXX0ko:;:d0XWWMWNKo,;d0NWWN0d:';lOXWWMMWWKxox0NMMMMMMMWXd:lkXNO:,o0WMWWWWWWNXKKXNWWWNWWWWWWWWWMWWWMMN0olxO0x:;d0NWWWWWWWWWWWMMMWWWWWWWWWWW    //
//    Xx;;odoloONWWWWMMMMWNXK0XWWWWNNNNWWXx::xKWMMWN0o:oONMMW0l,;xXWMMMWWNXKXNWWWWWWWNOocoONWMWWNKxl;;lkKNNXOo,,lONWMWWWMMWKd;ckXN0l,;dKWWWWWWXkl;cx00OdldOXWMMWWWWWWWMWKx::k0Oo',xXWWWNNXNWWWWWWWWWWWWWWWWWWW    //
//    Oo:oO0Oo:l0NWMWWWMMMMMMMMWMWX0doOXN0o,:ONWMMWXkc;oOKXNXOl;cONMWNKXNWMMMMWWWWWMMN0dclONWMWWWWWKkl;;;ccc;...ckXWWWMMMWKx:,lONWN0o,':dOKXX0d;...';cc;'.;dOXWWWWWWWWWKxc;oKXOl.,kNWN0kxOKNWWWWWWWWWWWWWWWWWW    //
//    c;oOXKx;.,dKWMMWWWWWMMMMMMMWXxccxXNKx;;d0NMMNOl'.':cllc:'.'dKWN0l:oOXWWMMWWMMMWKd;:dKWMMWWMMMMWXOdc::cllc:;cx0XNNNKOl;;lONWWWWXkl;;:clc::coddc:ok0Odc;;cdOKNWNX0d:,;d0NNk:.;ONXOxoxO00XNWWWWWWWWWWWWWWWW    //
//    .;kKXO:  .cxKWWWWWWWWWWWWWMWXOookXWNOl:oONMWKd'..';cc:,'...;x0NKx:',cx0XWWWWWN0d,.cONWMMMMWMMWMWWNXXXXXNXOl;,;:llc:;;cxKNWWWWWWWNKOdooodk0XNX0O0KNNX0xc'';coolc:.  ;kXWNk;.c0X0ddk0KOxOXWWWWWWWWWWWWWWWW    //
//    :xKKOl.   .,oOXWWMMWWWWWWMWWKxllkXWNOl:o0NWXk:';dOKXXK00Oxl;,ckXNXOo:;:lxkkkdl;,;oOXWMWWWWWMMWWMMMMMMMMMMWKOdc:;;;:lkKNWWWWWWWWMMMWNNXNNXKOxddddoodOKXK0kdoc;:clc,.:ONWNk;.:OX0xxkKXOoxKNWWWWWWWWWWWWWWM    //
//    xKXOc.      .:xKWMMWWMMMMWWNKOO0NWWKd::xKWNkc,cONWMMWWMWWWXkc,;dKNWN0d;..';;,,:oOXNWWWWWWWWWWWWWWWWWWWWWWWWWNXXKKKXXNWWWWWWWWWWWMMMMMMWKkoccldxxdc;:oOXWWNXKKKXKkl;l0NMNOc.,kXX0xdOK0kk0XWWWWWWWWWWWWWWN    //
//    XXOo.        .;d0NWWWWMMWWWWWNWWNXOo::dKNN0o;:xXWMWWWWWWWMWNKd:cxKWMWXx:,;lxk0XNWWWWWWMWNXK0kkxkO0XNWWWWWWWWWMMMMMMMMMWWWWWWWWWWWWWWMWNKOkOKXNWWNKOo:cxKNWWWWWW0oclkXWWWKx;;dKNN0dodk0XXNWWWWWWWWWWWWX0d    //
//    N0l'           .:oOKXXXXXXNNXK0xoc:coOXWWKx:;xKWMMWMMWWWWWWWWX00KNWMMNKd:ckXWWMMMMMMWWXOxl::;;;;;::odkKNWWWWWWWWWWWMMMMWWWWWWWWWWWWMWWWNNXXXNWWWMMWKxc:dKNWWWNKd;;xKNWWWN0o;:xKWNKxodOXWWWWWWWWWWWNKko:,    //
//    Kx,              .,:clccllolc::;,:d0XNWMNOc':ONMMMMWMWMMMMMWWWWWMWWMMN0d:cONWMMWMMMWXOo;;;coxkOkdc,...ckXWWWWWNX0O0KKKXWWWWWWWWWWWWWWNKkdooloox0XWMWKo,cOX                                                  //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PRUZ is ERC1155Creator {
    constructor() ERC1155Creator("Fine art by Marlon Pruz", "PRUZ") {}
}