// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zavoo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMNxcccccccccccccccclkWMM0d0MMMMMMMMMMMMMMMMMMMKocclkWXdlloxOXWMWX0xdolllodk0NWMMMMMMMMMMMMMM    //
//    MMMMMMMMMX:.... ..  .   ...cKMMK:.;0MMMMMMMMMMMMMMMMMXc...,OXl.   ..':lc'..  .......,lkXMMMMMMMMMMMM    //
//    MMMMMMMMMNd:::::::::;.   .lXMMKc. .:KMMMMMMMMMMMMMMMNo.. .xWKolc:;'.     ..;:clc:,.....,xXMMMMMMMMMM    //
//    MMMMMMMMMMWWWWWWWWWXo....dNMMXc.  ..cKMMMMMMMMMMMMMWk'...oNMMMMMWXo.     .cKWMMMWN0d:.. .:0WMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXl...'kWMMXl. ..  .cXMMMMMMMMMMMM0;...:KMMMMMMWx'. ...  .dNMMMMMMMNk,. .;0MMMMMMMM    //
//    MMMMMMMMMMMMMMMMMK:. .;OWMMNo...':'...cXMMMMMMMMMX0l. .,OMMMMMMM0,. .cOl.  'kWMMMMMMMMO,. .cXMMMMMMM    //
//    MMMMMMMMMMMMMMMWO;. .:0MMMNd.. .xNk'. .lXMMMMMMMWd,. ..xWMMMMMMWd.. 'kM0,  .oNMMMMMMMMWd.  'OMMMMMMM    //
//    MMMMMMMMMMMMMMWk,...lXMMMWx.. .dNMWx'...oNMMMMMMO,.. .oNMMMMMMMWd.  ,OMK;  .lNMMMMMMMMMx...'kMMMMMMM    //
//    MMMMMMMMMMMMMNd....oNMMMWk'. .oNMMMWx....oNMMMMK:.  .cXMMMMMMMMMk. ..xWk'  .dWMMMMMMMMNl...;0MMMMMMM    //
//    MMMMMMMMMMMMXo...'xNMMMWk,...lXMMMMMNd...:KMMMNl. ..,0WWMMMMMMMMXc...'l;. .;KMMMMMMMMNd. ..dNMMMMMMM    //
//    MMMMMMMMMMMKc. .,OWMMMWO,...cXMMMMMMMNd.'kWMMWx....'kXo:kXWMMMMMMK:. ... .;OWMMMMMMNO:.  .lXMMMMMMMM    //
//    MMMMMMMMMW0;....oOOOOOx;...'dOOOKX0OOO0xkWMMMO,. .'oXx. .,lxO0KK0kc.     .:x0KK0Oxo;....,xNMMMMMMMMM    //
//    MMMMMMMMWk,..  .......... .....;OKl...,kWMMMXc. .cOXWk:..  ........  .............. ..;dKWMMMMMMMMMM    //
//    MMMMMMMWx,............. ......:0WMXc...'xWMNo...;0MMMMN0dc;'......':lx0ko:,......',cdONMMMMMMMMMMMMM    //
//    MMMMMMMWKOOOOOOOOOOd'. .,dOOO0XMMMMXl...'xNk'..'kWMMWWNWMWXKK0OO0KXNWWNWWWNK0OO00KNWNNWWWNNWWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMXl...'kWMMMMMMMMMMXl....:,...dNWN0kOkx0Xk0MNk0MXkOkdOxkNMM0lxNKk0kx0KKOodKNMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd...'xWMMMMMMMMMMMMXl.  .. .cXMOco0WWNXOo0M0o0MOokloklxWMWxclxdokloKNM0oOMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKOOOKWMMMMMMMMMMMMMMXo... .;0MMOlok0OOXxlONOlxOdkkcdxlOMMXokXo;xxo0NWWkdXMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo. .,OWMMWWXOO0XWKO0XNKO0XWXOO0XWMMNKNMX0XXXWMMWXXWMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract zavoo is ERC721Creator {
    constructor() ERC721Creator("Zavoo", "zavoo") {}
}