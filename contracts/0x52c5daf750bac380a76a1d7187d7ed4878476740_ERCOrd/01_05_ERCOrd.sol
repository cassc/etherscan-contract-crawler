// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ERCOrdinals
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ERC ORDINALS. NO NODE REQUIRED                        //
//    FOR THE ETHER.                                        //
//    DO NOT LOSE YOUR KEYS DEGEN                           //
//    MMMMMMMMMMMMMMMMWX0kxdxxxxxxxkOKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMN0dc;,,'........',,:lkXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMXd;. .'.''  ',.. .''''. .cOWMMMMMMMMMMM    //
//    MMMMMMMMMXd;;'   ... .,;:c;. ....  .,;:OWMMMMMMMMM    //
//    MMMMMMMMX:.':;'. .  .,;. .':. .  ..,:;.'xWMMMMMMMM    //
//    MMMMMMMWo....''......'c'..::......''... ,0MMMMMMMM    //
//    MMMMMMM0;.,'..',,,....,:cc;'...',,''..,'.oWMMMMMMM    //
//    MMMMMMMO;';,,:cloll:..','.'..,clollc;,;,.oWMMMMMMM    //
//    MMMMMMMX:.',ox:...'ld'.,';'.cd:...'ox:'..kMMMMMMMM    //
//    MMMMMMMMO,.ck:     .o:.,,,..o:     .dx'.lNMMMMMMMM    //
//    MMMMMMMMWx.'do'   .::..,;'..'c'   .:xc.:XMMMMMMMMM    //
//    MMMMMMMMMO,.;:llc;;'...,,''. .,;:clc;,.lWMMMMMMMMM    //
//    MMMMMMMMXl...  ..   .,:clc:;.   ..   ..,OWMMMMMMMM    //
//    MMMMMMWO,....      .::,,;;,,c,.      ....oNMMMMMMM    //
//    MMMMMMK, .,;;.   .;cl, ','..:l:.   .,;,' .dWMMMMMM    //
//    MMMMMMX: .,,'....,lc;c:;;;;c:cl:'....',' .xWMMMMMM    //
//    MMMMMMMKl'....''..,;,;,...';,;;'..'.....;kWMMMMMMM    //
//    MMMMMMMMWXkc..',,......',;'.....',,..,o0NMMMMMMMMM    //
//    MMMMMMMMMMMWK:.,'....''..''''....,''dNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx.....,:;;;,::;;:'..'.;XMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO'.,;;okoxxdkkdxx::,'.lWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO,.,;;lxoddoxxodd::,'.oWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNo...';:;::;::;::,'..;OMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOo:,',,;;;;;;,',;cxXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWK0OO000000OOKNWMMMMMMMMMMMMMMMMM    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract ERCOrd is ERC1155Creator {
    constructor() ERC1155Creator("ERCOrdinals", "ERCOrd") {}
}