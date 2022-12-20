// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memento Mori
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ookKK0KNx;;lxOOdkkloxxk00kc,,ckNMW0ocodollkKOkoldxkdldxO0kxXMWX0xccdkXMMMXdxKxloodkk0XWWXXWNNWNOdxdo    //
//    dook0O0X0xokXWWNWKdoxkK0kxdclONMKocoxooooONX00kxoxkkxdoo0WNXOxl:ldKWMMMMWKkO0ocoddoloONNXNMMMMNOollo    //
//    xxddxxxO0KOkKWMMMNK0KKK0OxxxOXKocdOdlllxXNKKKXX0kOKkxdcckKxdoldONMMMMMMWXkdxkdodolodxO0xxXMWWWXxlcld    //
//    xxxdodxkKWNXNWMMNKKXWWX0Okdddl:cOXo',o0WMWNX000KX0kxdkxcldoddOKNMMXOXMMMNOkOOlokoldx0K0xx0X0O00dlllx    //
//    dxkkdod0WMMMMMWNOxONMMWKkdc;,:d00d,;xXMMMWXNNXXK0kodO0kdxdclxO0XMMWNWMWXOxxxkxc:oooxkxk0Okxdllxkkx0W    //
//    KXXXXXXNMMMMMMNKkxxONMMWk,'ck0Ox:'c0WMMWNOkXNKOkOOkOOkkxxc:odkkxONMMMMMXkdoddooldOOdldKWN0kOkxxkkKWM    //
//    0NX0kxxOXWMMMW0ddod0NMNkcl0XOd:':xNMMMMWXXXNXNNXXOxlcccoo:,lkOOkONMMMMMMXxdxoc:cxO0xokK0O0XWWKdx0KNM    //
//    KO00O0XKXWMMWKolkOKWNkllOXOd:..oNWMMMMMMMWNNNOdllc:clxO0OOkxxxxddkXWMMWKkdokkocokkOkOXK0NWWX0OKWNNMW    //
//    MNKXWMMMMMMWXOOXWMW0olxdool,..cKWWMMMMMMMMNOdxk0XWMMMMMMMMMMMWKkooxOkkK0kOxkklcdkkookXNWMMWN0x0WWNNW    //
//    XXXXNMMMMMMWKKNMWKdcod:;::c:;cdOKWMMMMMMNOdkXNkkNMMMMMMMMMMMMWXxo0WWXoldxkxoclxOOkkOXWWMMMNNNkkNN0XM    //
//    NWNKKNMMMMMMWWMKdlolc:cccdklclcoOXWMMMW0odXMMWNWMMMMMMMMMMMMMNxdKWMMMXl:ol:cdkOOOKXNWMNNWMKONWWNXNWM    //
//    XKXWXXMMMMMMMNxcll;,lddkkdc;,,,cd0WMMWklkNMMMMMMMMMMMMMMMMMMMWWWMMMMMMKlcxxONNKxo0K0NMMMMMXXWMMWMMMM    //
//    NXXWWWMMMMMNkccc;,codOKOdooc;;coxXMMWx:0MMWX00XWMMMMMWWMMMMMMMMMMXxONX00dxXXNNKocOklxNMMMMMMMMMMMMMM    //
//    MMMMMMMMMWOccxl;codOX0dlloolc:cx0NMMNloWMMW0xOXWMMMMNKXMMMMMMMN0xooKMKlddoK0kdloOXXXXWMMMMMMMMMMMMWN    //
//    NMMMMMMW0l:xxlcl:oXMXOxdlccllldKWMMMXlxMMWWN0OOOOOO0XWMMMMMWXNXddxddONOdkoONXKXWKx0WMMMMMMMMMMMMMMXk    //
//    OWMMMMXd:d0ocolcd0NMWWWNkoddxOXWMWMMWkoKNOookxc;;;;;;xWMMMMWWXo'...  :0WOl0WMMMMWNWMMMMMMMMMMMMMMMXO    //
//    NWMMWOloOxcldlclxONMMMMWXKKXNWMMMMMMXxcoK0kKO'   ... .xWMMMKxk;.....  ;KdlXMMMMMMMMMMMMMMMMMMMMMMMMW    //
//    MMWKddO0d;:cl0Xxod0WMMMMMWWWMMMMMMMKldk;oNW0,... .,'. lWMMNkkXk'  ..  ,0OlOWMMMMMMMNNWMMMMMMMMMMMMMM    //
//    MKdd0NKOl;ox0MMXxkk0WNWMMMMWWMMMMWKccooocOWo  ..  ..  :XMNo'cONKxoc:ld0WNllXWMMMMMN0XWMMWWMMMMMMMMMM    //
//    xlxKK0Oc::lx0MMWxxOkKxkNMNXKXWMMNkccll0koXWKo;;;;;;cdk0WXl. .'xWMNO0WMMWOcd0KWWMMMKx0WNNWNWMMMMMMMMM    //
//    x0xc:::l00doxNMMklokNXKKX00NWMNOlc:;oXMKxdkXMWWWKOKNX0NMO'    ,0MWNK0Odc:d0OkOONMMWOoodkkONMMMMMMMMM    //
//    KOlcc:kNM0:.:KMWxclOMWKkkXMMWOodoccOWMMMNx:xMMMWN0kkOKWMWx;;cokNW0l,..ckKWW0oxXWMMMMXkkO0NMMMMMMMMMM    //
//    xdodc,xWM0c;oKMXdO00WMWNNWWOooxxdONMMMMMMWx:oddoc;;;oXMMMWWKOXMMWXx, '0XxxOKWWWXNWMMWNWWMMMMMMMMMMMM    //
//    ;ckXk;oXMWxld0WxoKkd0KXXKOoldkO0KKWWXNMMMMWOl:,;,...:XMMMMWKOXWWKkxc.'dX0oxKXNWKKWMXkk0KWMMMMMMMMMMM    //
//    c0WM0odx0NxdkdXkldcxNOccl,ck0XMW00WNOKMMMMMMM0;:o. .:OK0kOkkOdokd:::;ldOXXNXKXWK0WMXdoOKWMMMMMMMMMMM    //
//    XkOWWkoccOd;lckxxKxxxc';kd:cONMWKOO0NMMMMMMMMWx:ddc;';;;,,,:d:,,.. .;kdxkodxkxxdd0XWX0OKWMMMMMMMMMMM    //
//    WXXNNXx:ld;cXxcoxOc':Ox'co:llkWWXkdxKXWMMMMMMMNoc0Xx. .  .;lol,.   .;kl;dddoccooc;cookNMMMMMMMMMMMMM    //
//    MMNklOWxol;ckOc,dd'.lOc,k0llllxdONWXkdXMMMMMMMM0cxXk;... ,c:cx:.   .oo:ldoc;;;,:xOkkkdokNMMMMMMMMMMM    //
//    WWWX0XMK:,ol'lkk00Ox0Nk,cNNd;'::dNMWXXWMMMMMMMMWockKOl;. 'dxxo'   'dd:ll,':ooocclldxx0KdoKWMMMMMMMMM    //
//    K0NMMMMMOd0k:coOO0OdXMNxl0MWx,;ckWKXWMNXNWWX0kd:...oNXx:;;oocc,.,:xOccc,:lllc;;cxd:;d0XNddNMMMMMMMMM    //
//    OKWMMMMMNdlKKOKWKOkkNKk0dxWWkcocoKO0WKc:c;;,.  ..  .oXWNXOdoxkdxxkKd...':c:;;;,kXo,.,oXMKxKWMMMMMMMM    //
//    NMMMMMMXkc,dOkXX00OXKl;od:oo:;l,;KMMN: ,,.:c..ol'.':l:lkXWWWNKOkk0k' .,:c;.'llk0dd:..;OMWKOXMMMMMMMM    //
//    MMMMWKxc,';c,oNXNWWNo:xOo,;xKKdoKMMWx''..:OKc;c''ccol. .,:kNNXNKko'.';:;,..cx0kckWK; 'dKWMXKNMMMMMMM    //
//    MMNOd:'.'dNNolOOkXWklO0xxkOOdcoXMMMXclO; .,oOd,.;xkl......'cooxc.'cc;'',..ckOo'cNMK: cdc0MMNKNMMMMMM    //
//    Xkxc'.,oKWMMKcldxK0oOklKWWk;;kWMMMMkoKXkc..,;ldolod:..',l:;o:'coxOkl'.,ldOOolc.cOo,'o0d.:KMMX0XMMMMM    //
//    xo;.,xNMMMMMXd;;ldl;:c:o0k:oNMMMMMXokMNXO,;doc:;:::,;xOdkko'.;O0o:llcoxxlooc:,..,:xXKo::',OWMKOXMMMM    //
//    :.'xNMMMMMWWWWl'OXo:oxc,,'dNMMMMMWdlXMMWd.cOc:lc:,',,;:oOkc..;olodddxkd,.,:,;codkkxdok0l':lxNW0kXMWN    //
//    .oXWMMMMMMNXNNd'xNo.,OOd,.kMMMMMWx;kNk0Nc.,oOx;,;;,,'..dXKx;. .,;,.'lxocodxkkxooddkK0o::dKO:cKWOkX00    //
//    KWMMMMMMMX0KXWK;;Kd..l0Wd.xMMMMMk.cNN0XWl'xOodxxkxol;,,,lkX0dl;...;dxxoccloc'..xKkdoodOkodkkc;kXOxO0    //
//    MMMMMMMMKxONWMMO,ox;ldkKo:OMMMMN:.kMWKXX:'0M0;;ddc:ccc:,.;x0XKkl..';:'.'cloc,.,cdddkOOkkOXXx:;lkOkO0    //
//    MMMWNNWNkkXNMMMWlcxlooxxcoNMWWMO':XWKO0o.,KMMKdolc:c;,:o;..:kKKOl'..,,:lcc::cccclxkkOKXKkdddldKKkkOO    //
//    MMNXNNW0k0xOWMMMxcdlooxOokMWKXWd.xWWWXo.'kWMMMWXkc,cllllod,.dX0O0Od;..;cc:;;;...;dkkO0OkkO0x:kWXkxO0    //
//    WNKXXxdxKWNWMMMMO:clddkkl0MMWWNc'xXMWd.cKMMMMMMMMX0kxxoooxl;xX0O0O0Ko,.',;,;;;:lllllloddxd:'.lWWXKNW    //
//    XKKNWKkkXMMWKKWMXoccldOOo0WNWM0:ckXNd'oNMMMMMMMMMMMWMWX0l;do:okkxx0NX0d'.:c::;;,''.',;:ldx:.':kNMMMM    //
//    00XWMMXONMMW0ONMWdol:dOKdOXOXWdcOKNd,xNMMMMMMMMWXXNWMMMMW0xdlcokO0NN0OX0;.,lx0KOdccllooodkc..cclONMM    //
//    OKWMMMX0NMMMMWMMNodx:cONxkWMM0cxXKk:xWMMMMMMMMMWOxkKMMMMMMWMMMNOxlclddkXKo'..',::;,,,,;;col'..:c;cok    //
//    NMMMMMK0WMMMMWMMNodXc'xWkdNMNllXN0lxWMMMMWKkXMMMNNNWMMMMMMMMMMWOc:ldoc:::ol..colc.,dxdlcccll'.,:cl::    //
//    MMMMMKkXMMMWXNMMWooNk.cN0dKWd:OKOooXMMMMMWOldNMMMMMMMMMMMMMMMMNc.kKKX00Okol:,lOkc;:dkkooxkxxl,';;;;c    //
//    MMMWKkKMMMWKooKMNocXNlcXKdkd:ONXOlOMMMMMMMNKNMMMMMMMMMMMMMMMWWW0ooox0KXNKOKN0oodkkdkxdxxOK0o,..','.'    //
//    MMMKkXMMMMMWK0NMWx:OMxcKNo,;kMMMkdXMMMMMMMMMMMMMMWNWWMMMMMWKKXNK0k'..,l0XKOXWWN0xOkdx0OxOdc;..,colll    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("Memento Mori", "MM") {}
}