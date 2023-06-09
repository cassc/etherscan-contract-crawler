// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ChibiGoros
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    [email protected]MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb>>>;;;;;JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM~  (vvrvrI;>;>;>;>jMMMMMMMMMMMMMMMF;;JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMYYY"""`  (rvvrvO&&x;;+&&jMMMMMMBYYYYYYYY5;;?YYWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN;;;      (vrvvvvvrI;>+vvdMMMMMMI;;;;;;;;>;>;;>JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN   .~..~....(;;jvv2.._;;;;;;vvr<>;zvvI;>;;;>;;;;;jMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN.....~(((-__(++JOOI__(+++;>;vvv<;>zOOI++++++++<<<(MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM...dyyI>;dyy$;;>;;+rvO;;;vrv<;;>;>zvvvrvrvrI   MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM#777777..~?<<!~~?77>;;jyyy111yyy111zzzz;;?11111jrvwJJJMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM#......~........(;;;;>jZZI;;+Zuu;;;wvrz;;;;;;;;jvvvvrdMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM.~..~.(>;zuu[``` `.uuZuZZuZZ<;;_``.;>jvvrvrI      MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM(((-..(++v77\```` .777777777!!!` `.<<?CCCCCC...   MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM>..zuu{.. ``` `             `` ```.;;;;;juuI   MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM<<<zOOwuZ{.. ``` ``            `` ``` ..(wwZ<<1wwwMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM...zOOXuu{.. ```` `          ` ` ```` ..(ZZk>>+ZZZMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM......zZu{.. `````  `          `` ``` ..(uuZuZuuZuMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM---_..?77>.. ``.......      .......`` ..(XXXggggggMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM;;;_..(;;<.. ``.lllllz      +lllll:`` ..(vvdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM>........ ```               ` ```` ..(vrdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM&((----.. ``....         ....` ``` ..(vvdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKvr{.. ``,NN#   ;;;   MNN}````` ..(rvdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMY77C11:.. ``.77^`  ;;;   ?77! ```` ..(11?77TMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM>.~(;><.. ```` `   ;;;      `` ``` ..(;;<.~(MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM>..jvv{.. ``` `    ;:;;;;   `` ``` ..(vvI..(MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMa((Jvr{.. ```` `   <<<<<<   ` ```` ..(OOG(((MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKvv{.. ``` ``  `......`  `` ``` ..(??dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb==:.. ``` `.wwwwwwwwwwww_````` ..(=?dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMR??<.. ``   .ZuuZuuZuuZZu_   `` ..(==dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMR?=<.. ``.ZuZuZuZZuZuZuuZZuu}`` ..(??dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMR?=i((-``.uuV777777777777zuZ}``.(((??dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMR????=:``.uZI   ~~.~~.   juu}``.???=?dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMR?=???=??????=?<      <??=???????=??=dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk&&x=??=?=??=??<......+=??=?=??=??u&&dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMb??=??=?=??=?==?=?????=??=?=??=dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNP<<<???=????=??=??=??=<<<<<<JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF~~(??=??=????=??=????:~.~~~JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF~~~~~(?=?=?=??=??=~...~.~~~JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#""5~~~.._<<<<<<<<<<<<~...~.~~~JMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]   ~~~.~.....`.```..`....~.~~~(vvdMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMr````. ..~~.~...`.`````.`....~~(zzzrrwUUWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM}   .` ~..~~....`..```.`...._~~(llzrrrvvdMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMM~  `.` ~._~:(::<...``.```.``...(?????zlllrrrvvvMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM"""`   ..-_____(;;<------...------(?>1??1zzzOOOrrrMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM   `.`..~_~~(;:;;;;::;::::;;;;;>>;>>>????=?=llltrtvvvMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN   ..`..~~~~:;;;;;;:;::::::::::;;;;;;;;;>>>??????=lllrrrvvvMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMB```..._~~_::(;;;;;;:;:::::::::::::;;;;;>>>>>????=?llltttrrrMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM#   ```...~~~:;:;;;;:;:::::::~::::::::::;;;;;;;>>>???????lllrrrrvvMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM#77^`` ...~~~(::;;;;;;<::::::::~::~::::::::::;;;;;;>>>>?????===lllOrrVWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMF  `.`.~~.::~;;;;;;;;;:::::::~::~::~~::::::::::;;;;;;>>>>??????llltrtrvvdMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CG is ERC1155Creator {
    constructor() ERC1155Creator("ChibiGoros", "CG") {}
}