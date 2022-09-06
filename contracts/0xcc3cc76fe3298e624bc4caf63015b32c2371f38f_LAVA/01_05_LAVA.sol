// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Earth
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkkkoccoddxxxxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOOkoclc;:dddo:;;:c::loxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xlllcll::col',c' .lo:',o:lNMMMMMMMMMMMMMMMMMWWNWWMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMWXxddclo;:ol;,llcc,;o,.;o:..;o:xWMMMMMMMMMMMMMXOdlol:cooONMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWKkoloclol:llloolc;cod:..:d' ,d:lNMMMMMMMMMMMWOoodc;od,oKx;cKMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMXkloxollc:ldoxkxooxxd;cd'.oo. ldc0MMMMMMMMMMMNd:xNWxcdl;oOxc.lWMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMNOdc,lo:lxxOKNWMMMMMMMMKldo,oo;'oolXMMMMMMMMMMWx:dkOxool,;ccc:.cNMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMXxl:;:odxKWMMMMMMMMMMMMMNolxdxxddxl:OMMMMMMMMMXxoddoddc:coollo:'xMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMKddolxOXWMMMMMMMMMMMMMMMWXxoooddddoooONMMMMMN0d;.,olc:',odoxOKx,lNMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMWxlkOKWMMMMMMMMMMMMMMNKxo:;'........'',;:okKXx:xd'l0OOl;ooldKXxcdNMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMNKNMMMMMMMMMMMMMMNOo;... ..,;;:::::::::::;,:odkd,:0WMd;xdccloo0WMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;.....':oxkdl;.     ...,:cc;,cdo,;oo;.,dkOKNMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.....,::;,..';:ccc'.........:c;':xddxl,oXMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.....,oc..';;;:,..;oo;..........:l,.lxdoOWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMWx.....'cOd..:c'.',ll.  ;d' .........'l;.;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMWd.....;l;ol..c; .:clc.  ;d, ......... 'l;.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMWKkxolok0KKK0XWk. ...co' :d' 'c;..'...:ld:............ ;l. ;0MMMMMMMMMMWX0XWMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMNxoo:;ccccclodckK:....co....:o,..,;;:ldkdo:'''''''...... 'o, .lNKO0KKKOxooolloKMMMMMMMMMMMM    //    //
//    //    MMMMMMMNkc:dd;;l;;o;.,ddOk. . ;d, ....;o;.....,::::::::::::::::'. 'o;  'Ox:oooolc::;,clc0MMMMMMMMMMM    //    //
//    //    MMMMMMKdlod:':dl;:oo';do0d....oc...... 'oc..'lc;;'..   ..''...,l:.,d, ..x0oxc;l;,:',dccll0MMMMMMMMMM    //    //
//    //    MMMMM0coocdc,co::olclxdlKd.. ,o, ..,;:;,;dc..d0Ok:'..':;;;;;c;..clll....x0ox:;x;,d:.;'.lldWMMMMMMMMM    //    //
//    //    MMMMXolxc,oo:do:oxxk0XXXWx.. ;o..:oc:;;;:kO, ,xl...,dd;..,'..l; 'kk'.. 'Okoko::'..,;,..olcNMMMMMMMMM    //    //
//    //    MMMMxcodl.:dlccdKWMMMMMMMK;. ,l,co...;;'.'dl.....cok0: 'oc..:l' ;x:....cXOoOOxlcclc;;:od,cNMMMMMMMMM    //    //
//    //    MMMXoldoxddolkNMMMMMMMMMMWx. .ckx, ,l;:o, ;c...'o:.,xc .:c;::..'c,....'OMWWMMNl,l:::;coo;oWMMMMMMMMM    //    //
//    //    MMM0od:,ddcdXMMMMMMMMMMMMMNd. ,Ok. ;l..,..c:..,o;. .;oc'.....;lc'....'kWMMMMMMkcl;cdxc'llOMMMMMMMMMM    //    //
//    //    MMM0ld:;ocxWMMMMMMMMMMMMMMMNx..;kc..:c;,;::..,o;......;cc::lkx:.....,OWMMMMMMM0;cko.,do:oNMMMMMMMMMM    //    //
//    //    MMMNookdcxWMMMMMMMMMMMMMMMMNkd:.,ol'..,,,...co,........ .'cl;......lKMMMMMMMMMOlocll;olc0MMMMMMMMMMM    //    //
//    //    MMMMkcocdWMMMMMMMMMMMMMMMW0o:;lo;.:ddl:::ccc:....... ..:cc;......cOWMMMMMMMMMMx:o:;cccoOWMMMMMMMMMMM    //    //
//    //    MMMMW0oxNMMMMMMMMMMMMMMMW0c'::,:lo:';oxxoc'......,;;ccc:'.....,l0WMMMMMMMMMMMKoldc;lockWMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMWkc;;;';c;cO0d:,,;;;;;::::cc:,.. ...;lkXMMMMMMMMMMMMMXollcdccd0WMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMX:.cc:';dONWMMWXOoc;,'.......',;cok0NMMMMMMMMMMMMMMMKoldlloldKWMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMXc,,';dKWMMMMMMMMMMWNXOdoooddxxxXMMMMMMMMMMMMMMMMMW0lcodddoxNMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMNo,,;kNMMMMMMMMMMMMMMM0lllcc:locOMMMMMMMMMMMMMMMMNOoc;cookXMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMk;lXMMMMMMMMMMMMMMMMMkld:....ldOMMMMMMMMMMMMMMMXxoc;:dOXWMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMKl;do::::lclXMMMMMMMMMMMMNOxxlok0NMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0cl:,c,.,ox:'kMMMMMMMMMMMMXxxOOXWMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxccdl;codo;ll:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxlol:ll..;xocllkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkooloc;;lo:;oOo;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kddoccdxdl;'cdcloolkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl;okkd:;lxdoxdllxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxxxxxxxxxddkOOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LAVA is ERC721Creator {
    constructor() ERC721Creator("New Earth", "LAVA") {}
}