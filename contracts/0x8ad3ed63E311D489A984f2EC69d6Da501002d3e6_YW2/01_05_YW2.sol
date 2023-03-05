// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YRWRLD EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                     //    //
//    //                                                                                                                                     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOxol:,'...........';coxKNMMMMMWMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxl:,..........',,;;,,'.......:d0WMMXNMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKko:'......',:ldkO0KXNNNNNNXKOxo:'...'lKWO0MMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dlcclxKWMMMMMMMMMMMMMMMMMMMMMWXkdo:'.....':lc:;;:ld0WMMMMMMMMMMMMMMWKx;...dXdkWMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMXo'......,xNMMMMMMMMMMMMMMMMMN0d:'......,lxOXXx,.......oXMMMMMMMMMMMMMMMMNx,'kK:lNMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWNXKKKNWWx..........dNMMMMMMMMMMMMWNOo;......,cx0NWMMNd..........xWWXKKKXWMMMMMMMMMWOd0k.;0MMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMW0o;'..';lkd...........dNMMMMMMMMMNOo,.....;oOKXWMMMMMNx'..........dx:,...,:dXMMMMMMMMWWK:..oNMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMNd'.........ll..........'xNMMMMMN0o;.....:d0NMMMMMMMMMWx'..........cl.........;OWMMMMMMW0c....oXMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMO'...........oo'.........'xWMWKx:.....:dKWMMMMMMMMMMMWx'..........lc.....,;;::ckNMMWNKkl'......;dOXNWMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMk'...........;Ox'.........'xKo'....;o0NMMMMMMMMMMMMMWx'.........'dd....:0XXKK0Okxol:,.............';cldxk0KXNW    //    //
//    //    MMMMMMMMMMMMMMM0;............dNk,.........'oc..'lONMMMMMMMMMMMMMMMWk'.........,kKc....:OXXKKK00Okxdl:'..........,codkO0KKXNWW    //    //
//    //    MMMMMMMMMMMMMMMNl............;0WO;.........'odxKWMMMMMMMMMMMMMMMMWk,.........,OWk'......',,;;l0MMMMMWXk:.....'l0NWMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMWx.............dWM0:.........,kWMMMMMMMMMMMMMMMMMWk,.........;0WXc............,0MMMMMMMMNd...,kWMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMM0,............:KMNO:.........,kWMMMMMMMMMMMMMMMWO,.........:KMMk'............cXMMMMMMMMWXl..xWMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMXc.............x0c;oc.........,OWMMMMMMMMMMMMWWO,.........cKMMNl.............dWMMMMMMMXkKO,:KMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMWx.............:o'.,xl.........,OWMMMMMMMMMMWOo;.........lXMMMO,............,OMMMMMMMWx,xKcoWMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMM0,............'oo;dXNd.........;OWMMMMMMMMW0;..........oNMMMNo.............cXMMMMMMM0,.oXxkMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMXc.............c0NWMMNx'........;OWMMMMMMW0;.........'dNMMMM0,.............dWMMMMMMK:..cX0KMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMWd.............'kWMMMMWk,........'o0XNNX0o,.........'kWMMMMNo.............'OMMMMMMXl...lXNWMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMO,.............cXMMMMMWO;..........,;;,...........,OWMMMMM0;.............:XMMMMMXo...;0MMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMX:.............'OMMMMMMW0;.......................;OWMMMMMWd..............oWMMMMNo...,OWMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWo..............lNMMMMMMWK:.....................:0MMMMMMMK;.............'kMMMMXo...,kWMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMWk'.............,OMMMMMMMMKc...................cKMMMMMMMWd..............:KMMMXl...,OWMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMW0xk:..............oNMMMMMMNkdc.................cd0WMMMMMMK:..............lNMMKc...;OWMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMNx''dl..............'xNMMMMNd'.ll..............,cl';OWMMMMXo..............'kMW0;...:0WMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMXo...cd'...............:oddo;....ll............ckl....:oddl,...............;KNx,...lXMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMWKc...,k0;.........................:d,..........,dx;.........................lKd...'dNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMW0;...;OWNl.........................:x;..........;dx;.........................x0;..;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMWO;...cKMMWx.........................:d;..........;dx;........................,0k'.lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMWO,...lXMMMM0;........................:d;..........,dx;........................cKo;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMWO,...lXMMMMMNl........................:d;..........,dx;........................xXOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMM0;...lXMMMMMMWx........................:d;..........,dx;.......................,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMK:...cXMMMMMMMM0,.......................:d;..........,dx;.......................cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMNl...:KMMMMMMMMMXc.......................:d;..........,dx;.......................dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMWx...,OMMMMMMMMMMWd.......................:d;..........,dx;......................,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMK;...xWMMMMMMMMMMMO,......................:x;..........,dx;......................:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMWd...cXMMMMMMMMMMMMXc......................:x;..........,dd;......................oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMK;..'kMMMMMMMMMMMMMWd......................dO,..........,x0l.....................'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMWx...cXMMMMMMMMMMMMMMO'....................dN0,..........,0WKc....................:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMNl...dWMMMMMMMMMMMMMMK:...................dNM0,..........,0MMXc...................oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMXc..'kMMMMMMMMMMMMMMMNo..................dNMMK:..........;0X0xkc.................'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMX:..'OMMMMMMMMMMMMMMMMk'................dNMMMWO;........;dl,..;dc................;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMXc..'OWWMMMMMMMMMMMMMMK;...............dNMMMMMWXkocc:::ll;....;kKl...............lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMNo..;0XKWMMMMMMMMMMMMMWd..............dNMMMMMMMMMNKxc;,...,:lONMMXc.............,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMO'.oNkdNMMMMMMMMMMMMMMNx,..........;xNMMMMMMWN0d:'....'ckXWWMMMMMXo'..........:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMNkxXKc;OWMMMMMMMMMMMMMMWXkolccccldOXMMMMMNKkl;.....,lkXWMMMMMMMMMMWKxolccccldONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMWWNKk:..,d0NWWMMMMMMMMMMMMMMMMMMMMMMMMNKko:'.....;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    WNX0kd:......;ok0KNWMMMMMMMMMMMMMMMWNKkdc;......,lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMWNXk:..,x00OkOKXNWWWWWWNNXKOkdl:,.......;lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMKc;ONd,....,;:::::;;,'........';cdkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMWkxNW0dc;'.............',:loxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMXKWMMMWNXKOkkxxxxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //                                                                                                                                     //    //
//    //                                                                                                                                     //    //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YW2 is ERC1155Creator {
    constructor() ERC1155Creator("YRWRLD EDITIONS", "YW2") {}
}