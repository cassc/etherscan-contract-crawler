// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phases of Web3-1 by Skull
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//        $$$$$llllllllll||||||   __________________________________________________________ '|||||lllllllllll$$$$$$$$$$    //
//        $$$$llllllllll||||   _______________________________________________________________   |||||llllllllll$$$$$$$$    //
//        $$lllllllll|||||   ____________________________________________________________________  |||||lllllllll$$$$$$$    //
//        $lllllllll||||   ________________________________________________________________________   |||llllllllll$$$$$    //
//        llllllll||||   ____________________________________________________________________________  ||||llllllllll$$$    //
//        llllll|||||  ________________________________,[email protected]@@@@@@@@@Bgg,_______________________________  |||llllllllll$$    //
//        llllL||||   [email protected]@@@@$$M$$$$%%%@@@@@g_____________________________   |||lllllllll$    //
//        llll||||   [email protected]@@[email protected][email protected][email protected]@@@@@g____________________________  ||||llllllll    //
//        llL||||   ______________________________]@@$$$&[email protected]@@@@@@@@g____________________________ |||llllllll    //
//        ll||||   __________________________,,g_%@%@*[email protected]@@@@@[email protected]@@g__________________________  |||lllllll    //
//        l||||   _________________________)L$C)@g#[email protected]@[email protected]@[email protected]@@@@@@@%@@@@@__________________________  |||llllll    //
//        l|||   [email protected]@@[email protected]@@@@[email protected]@@@@@@@@%@@@@@,_________________________  |||lllll    //
//        ||||  [email protected]%[email protected]@$%@@@@@%[email protected]@@@@@@@@@@[email protected]@@[email protected]@@@@[email protected]@@__________________________  |||llll    //
//        |||   _________________________]@$$M%,g%@@@@@@h#@@@@@@@@@@@@[email protected]@@@[email protected][email protected][email protected]$$M$k__________________________ ||||lll    //
//        ||    _________________________]%[email protected][email protected]@j$$$%][email protected][email protected][email protected]@[email protected]@@[email protected]$%[email protected][email protected][email protected][email protected][email protected]__________________________  |||lll    //
//        ||   [email protected]$%@[email protected]}M%$$%@@K]M%%%MMMMMjMM%@[email protected]$$QF__________________________  ||||ll    //
//        ||   _________________________u#@#@@@ML"`_____"|*||',;,*T'' *_____`*%[email protected][email protected]__________________________  ||||ll    //
//        ||   __________________________%@@[email protected]@`[email protected]$$#[email protected] __________'%@@$M$___________________________  ||lll    //
//        ||   __________________________%[email protected]$________ ___]][email protected]@ L ___________%$F%i___________________________  |||ll    //
//        |   [email protected]$$__________ ,_#[email protected][email protected]_________ [email protected]@@y!____________________________ |||ll    //
//        ||  ___________________________|][email protected]_L| _____,$'@g$%_[_%[email protected]@'s,___  _ [email protected]$$$j___________________________  ||||l    //
//        ||  __________________________.|]@@@@,l ,_/lM'gg$NC__[_]*[email protected]@g'%Mk,,{L'@Mj$$JL__________________________  ||||l    //
//        ||   ________________________,;g%@@@[email protected]@,[email protected]@@@[email protected]@U  __L*[email protected]%[email protected]@mggg#@[email protected]@@xW__________________________  |||ll    //
//        ||    ________________________'jj%$"j[]Mg%@@@%@%r'F____'w])]@[email protected]@@[email protected]]$$FQ%_'_________________________   |||ll    //
//        ||    __________________________\%%@@@]@$$C,g,$QgWL__,_,j#M$_gw,*MM%@]@Wl_____________________________  ||||ll    //
//        |||   ____________________________%%CW%[email protected]@gLj#[email protected],[email protected]$[l|g,|''!L____ ___________________________  |||lll    //
//        |||     ____________________________}@@W_"[email protected]@$wF]$'[j`%%@[email protected]@l*F'_!)%L______________________________   |||lll    //
//        ||||    ____________________________}$%],_'[email protected]@@[email protected]]@[email protected]][email protected]@!|`_.[#L______________________________   |||llll    //
//        L||||  _____________________________}$]JF;-J])%]MB$"]M_*jPM]*#F___$KM]L_____________________________  ||||llll    //
//        l!|||     __________________________}@*kQg__!jL}|,,|L_ `_{| || __$%[email protected]____________________________   |||lllll    //
//        ll!|||   ___________________________],[email protected] __, __'__' '''T_',_, [email protected]@hF___________________________   |||llllll    //
//        llLL|||     ________________________}[email protected],_'LL_`lLj_ljL'_|'_,[email protected]@@$Q]F__________________________   ||||llllll    //
//        llll!||||    _________________________*]@@@@gjm,_'__','__'_,@@[email protected]@@[email protected]*'_________________________    ||||lllllll    //
//        llllll||||     ________________________]%@%@M)#]@@[email protected]@[email protected]]@@]@]@%@@@@F__________________________    ||||llllllll    //
//        llllllL||||     ________________________"%@[email protected]@@@[email protected]%@@5]%@@M"________________________     ||||llllllll$$    //
//        llllllllL||||      _______________________'YLg][email protected][email protected]@@@%@[email protected]/_________________________ _    ||||lllllllll$$    //
//        $$llllllLL|||||  _   ________________________'j%[email protected]@%MMM%%@@@M`_________________________      ||||lllllllll$$$$    //
//        $$$lllllllL!|||||  _   _________________________''''''''lM*`__________________________     |||||llllllll$$$$$$    //
//        $$$$llllllllL||||||    _  ________________________________________________________       |||||llllllll$$$$$$$$    //
//        $$$$$$llllllllL||||||        _________________________________________________     _  ||||||lllllllll$$$$$$$$$    //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract POW1 is ERC1155Creator {
    constructor() ERC1155Creator("Phases of Web3-1 by Skull", "POW1") {}
}