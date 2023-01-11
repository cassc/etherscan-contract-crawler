// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life in Death
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//    ███████ ██      ███    ██  █████  ███████     ████████  █████   █████  ███████ ███████  ██████  ██████      //
//    ██      ██      ████   ██ ██   ██    ███         ██    ██   ██ ██   ██ ██      ██      ██    ██ ██   ██     //
//    █████   ██      ██ ██  ██ ███████   ███          ██    ███████ ███████ ███████ ███████ ██    ██ ██████      //
//    ██      ██      ██  ██ ██ ██   ██  ███           ██    ██   ██ ██   ██      ██      ██ ██    ██ ██   ██     //
//    ███████ ███████ ██   ████ ██   ██ ███████        ██    ██   ██ ██   ██ ███████ ███████  ██████  ██████      //
//                                                                                                                //
//                                                                                                                //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$           //
//    [email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@BBBBBBBBBBBBB%%%%%%%%%%%%%B%%%[email protected]@@[email protected]@@@@@@@@@@@@@@$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@BBBBBBB%%%%%%%%%%%%%%%8&&WWW&8%%%%%%[email protected]@@@@@@@@@@@@@@@$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@BBBBBBBBB%%%%%%%%%%%%%88&&&W##ahMW&88%%%%%%[email protected]@@@@@@@@@@@@@$$$$           //
//    [email protected]@@@@@@@@@@@@@@BBBBB%%%%%%%%%%%88888&&&&&WWM*ohha*WW&&8888%%%%%[email protected]@@@@@@@@@@@@@@$$           //
//    [email protected]@@@@@@@@@@@@@@@BBBBB%%%%%%88888&8&&&&WWWMMM#*oaaao*MW&&&888888%%%%%[email protected]@@@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBBB%%%%%%888888&&&&&WM#***oaaaaoaoooo*#MWW&&&8&8888%%%%[email protected]@@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@[email protected]%%%%%%888888&&&WWM#*ohkbkkkkhaaooo*o**#MMWW&&&&88888%%%[email protected]@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%%%%8888888&&&&WMM#ohbbbbbkkkhhaaoooooao*#MMMWW&&&&&888%%%%[email protected]@@@@@@@@           //
//    [email protected]@@@@@@@@@@@BB%%8&&&&&&&&&&&&&WWW#oabddddbbkhhhaahaaaoaaao****###MWW&888%%%%[email protected]@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%8&Mha**MMWWWWWWWM#okdddddbkkhhaaaahaaaaahhaaohkkao#MWW&&88%%%%[email protected]@@@@@@@@           //
//    [email protected]@@@@@@@@@@BBBB%%8&M*hhhho*#MMWWM#*akddppdbbkhaaaaahhhhhhhhhhhhhhhhha*#WW&&88%%%%%[email protected]@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%88&Mokhhhhaa*####*abdddppdbbkhhhhhhhkkkkkhkkhhhhhhhhha*#MW&&88%%%%[email protected]@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%88&Mohkkkhhaaoo*oakddpppddbbkkkkkkkkkkkkkkkkkkhhhhaaaha*#MW&&88%%%%[email protected]@@@@@@           //
//    @@@@@@@@@@@@BBBBB%%%8&&M*abkkkhhhhhahkbdpppppdbbbbbbbbbbbbbbkkkkkkkhhhaahhha*#MW&&88%%%%[email protected]@@@@@@           //
//    @@@@@@@@@@@BBBBB%%%%8&&M#okbbbbkkkkkkddppqpppddbbbbdddddddbbbkkkkkkhhhaaaahho*MW&&88%%%[email protected]@@@           //
//    @@@@@@@@@@@BBB%%%%%88&WW#okbbdddbbbbdpqqwqqqppdddddppqqqppddbkkkkkhhhhaaaaahho#WW&&8%%%%%[email protected]@@@@           //
//    @@@@@@@@@@BBBB%%%%888&WM*akddddddddppqwwmwwqqppddppqwwwwwqqpdbbkkkhhhhhaaaahha*#W&&&8%%%%[email protected]@@@           //
//    @@@@@@@@@BBBB%%%%88&&WW#ohbbddddpdpqqwmZZmmwqqqpqqqwmZZZmmwqqpdbbkkkhhhaaooaaho*MW&&8%%%%%[email protected]@@           //
//    @@@@@@@@@BBB%%%%888&&WW#ohbbbbddppqwmmZZZZmwwwqqwwmZOOOOOOZmwwppddbkkkhaaaaaaha*#WW&&8%%%%[email protected]@@           //
//    @@@@@@@@@BB%%%%888&&WMM*akkbbdddpqwmZOOOOOZZmmmmZOO00QQQQQ0OZmwqppdbbkhhaaaoaaha#MW&88%%%%[email protected]           //
//    @@@@@@[email protected]%%%%888&WWM#okbbbbddpqwmmZ00Q0Q000000QQLLCCCCCCLQ0OZmwqppdbkkhaaaaahao#M&&&8%%%[email protected]@@           //
//    @@@@@@BBBBB%%8&&&&WMM#ohbbddddpqwwmZ0QLLCCLLLCCJJUUUUYYYUUJCLQ0OZmwqppdbkhaaaahka*MW&88%%%%[email protected]@@@           //
//    @@@@@@@BB%%%8&WWMWM#*ahbddpppqqwmmO0QCJJUUUYYXXzcvuuuuvvcXYUJLQQ0OZmwwqpbbkhhhkbko#W&&8%%%%[email protected]@@@           //
//    @@@@@@@B%%%&&Mokho*oahbddpqqwwmmZO0LCUYXzzzccvnxjft///fjxucXYJCLQQ0OOZmwqdbbkkbbbo#M&&8%%%%[email protected]@@           //
//    @@@@@@@B%%8&#okkkkhhkbdppqwmmmZO0QLCUXzvuunxrft|)1{}}[{1|fxvzYUJCCCLLQ0Zmqpbbbbbka#M&&8%%%%[email protected]@           //
//    @@@@@@@B%%8W*hkkkkkkbbdpqwmZZO0QLLJUXcuxrjft/(1}[?-____-[1/jnczYYYUUUJCQOZqpdbbbka#M&88%%%[email protected]@@@@           //
//    @@@@@@@B%%&MokbbbkkkbbpqwmZO0QQLCJUzcnxjt/|)1{[?-+~<<<<~+?})fxuvcczzXXUCQOmqpddbka#M&&8%%%[email protected]@@@           //
//    @@@@@@@B%%&#abbbbbkkbbpqmZO0QQLCUYzvnrt/()1{}]-+~<>ii>>><+-})/frxnnuvcXUCQZmqppbka*MW&8%%[email protected]@@@           //
//    @@@@@@BBB%&#abbbbbbbbdqwZO0QLCJUYcuxjt/(1{}]?_~<>>ii!!ii><+?[1(/ffjrnuzYJL0Zmqpbbho*M&8%%[email protected]@@@@@           //
//    @@@@@@@BB%&#akbbdddddpqmZ0LCUUXcvnrf/|){}[?-+~<>i!!!!!!ii><+-[{1(|/frncXUCQOZwpbkhhh#&8%%%[email protected]@@@@           //
//    @@@@@@@BBW#*akbbddppqqmZ0LCUXzvnxjt|(1{}[?-+~<>i!!!!!!!!ii><+-]}{)(/fxvzUCLOZwpbkha*M&8%%[email protected]@@@@@           //
//    @@@@@@BWWMM#*akbdppqwmZ0QCUXcurf/|)1{}[]?-+~<>i!!!!!!!!!!ii>~+-?[{1|truzUCQ0Zwqdkko#W8%[email protected]@@@@@@           //
//    @@@@@&&WWWWM#oakbdpqwZOQLJXvnj/(1{}[]]?-_+~<>i!!!!!!iii!!ii><~_-][{)/juzUCQOZmqpdko#&8%[email protected]@@@@@@           //
//    @@@BWWWW&&WWM#*akdpqwZ0QCUznj|1}]]?---__+~<>i!!l!!!iiiiiiiii>~~_-][{(fuXCQOZmwqqpkoM&%[email protected]@@@@@@@@           //
//    @@BW&&&WWW8WWM#*akdpwmOLJXvr/1[?__+++++~~<>i!lll!!i>>>>iiiii><~+_-]})tnU0mwqqqqqpbkM8%[email protected]@@@@@@@@           //
//    @@&&&WWWW&WW&W#*ohbdqmOLJznf)[?+~<<~~~<<>>i!llll!i>><<>>iiii>><~~+_?}([email protected]@@@@@@@@           //
//    @&&8WWWWWWWWWWW#ohkdqmOLJzx|{?_~<>>>>>>>>i!!llll!>><<<<>>iiiii>><~+_?}(jcCmqppppqdkhaM#%@@@@@@@@@           //
//    %&W&&&WWMMMWMM#o*hkdqmOCYvf)]_+<>>>>>>ii!!llll!!i>><<<<<>>iiiii><><~+?[)fvCmqpppppkoo**#[email protected]@@@@@@@           //
//    &&WWWW&&WWWM#*ooakkpwZQJzx|}-+<>iiiiiii!llllll!!i><<<<<<<>ii>>>>>><<~_?}(fcLmqqqpqdkao**##[email protected]@$$$           //
//    &&&WWWW&&&MMM*oakbdqZ0CXut1]_~>iiiiiii!!!llll!!i>><<<<<<<>>>>ii>>>><~+-[{|rX0wwqwqpbhao**#[email protected]@$$           //
//    &&&WWWWWWW&&M#*akdpm0LYcj(}-~>ii!!!i!!!!ll!ll!iii>>>><<<<<<>>>>>>><<~+-]{(fnJOwwqqqdhao*#[email protected]@           //
//    8&&&&&&WWMMMWW*hbpwOLUznt1[_<>iii!!!iii!!!!!!!!iii>>>>><<<<<<<<<<ll>+~-]})txXQmwwwqdkaMWMMM&WWWW&           //
//    &&8&&&&&WWM####MkpZ0CYvj({?_Q(....lwIiiii>i>iiii!iiii>>>><<<<?Z.   ..X|[{)tnzCZmmwwpho*#MMMW&&WMW           //
//    &&WW&&&W&WM##ooaahZQCXnf)[u".      ..u!>>>>>iii!!!!!iii>><~in...       /()txzJOmmmqpbao#MMWWWWW&W           //
//    &&WWWW&&WWWM*aakbpwOJznt)v.      !MMU.z~>>>>>ii!!!!!!!i>>>~Y.xM#;      .1}/xcU0ZZmwqba*MMWWWW8MWW           //
//    &&&&WWWW&&WM*ohdpqmQJzxt[j        Yp, .]i>>>iii!!!!!!!ii>>!I.!aw'       !t|juYQOOZwpka#MMM&8MWWW&           //
//    WWWWWWWMMMWW**akpwmQJznt}t            `?!!iiiii!!!!!!!!!ii>/            _?(fxzCQ0Zwpka*MW&WWW&&&&           //
//    &&&&&&WMM###MMokdpm0CXnt1n>          '0l!!!!iii!!!!!!!!!!!i+-.       . lY{(trcUL0ZqdhoMMMWW&&&&88           //
//    8W&W&WWWW##**o*obpm0CYuf)[{v'      .?j!!l!!!!ii!!!!!!!!!!!ii!v;   .. :Y/(tjxuXJQOwpda*#MMW&&&&&88           //
//    @@%&W&WWWM#**ahbkhmOQUvj(}?_<t//j|j~i!!!!!!!!!!!!!!!!!!!!i>><~~]unnzj/jxucXYJCQOmpbho#MMW&&&88888           //
//    @@[email protected]@&WWWWMM#oakpqmq0CXnt1[-+<<i>!iii!!!!!lYL?,:I;;I,":!>>~+_-]}{)|tjxvXJQOOOOZwpbka*MWW&&&[email protected]           //
//    [email protected]@%WWMM#*aakdqmOQJznt)[-_~<>iiiiiiii!Ymwmwmmmmwmmwq1~_?[{1)(/fruzYC0mwwwwqdkha*#MW&[email protected][email protected]@           //
//    [email protected]@B&WM##*#M#abw0JXuj|{]-_~<>>ii!!ii>mwwmwwwwwwwmt~+-[{1(|/fxvXJQOmqqqppbkao*MMW&&[email protected]@@$$$$           //
//    [email protected]@@&M#888#hbqwOLUznf({[?-+~<>>>iiii>ll(ZobQf!>~+_?[{)|tfxvYC0Zwwqpdbkha*#MW&&[email protected]@$$$$$$$$           //
//    [email protected]@@%MMM##ooobdqmOLUzurt({[?-_+~~<<<<<<<<<<<~~+_-?]}1(tjxvYC0Zwqpdbkha**MW&%@@@$$$$$$$$$$           //
//    [email protected]@@%&&&WWM8M*oabdqwmOQCYzurf|){}]]?-________--?]]}{1(/fruzULOmwqdbkao**MW&[email protected]@[email protected]@$$$$$$$$           //
//    [email protected][email protected]@%%%888&%&WM#*aakbddpqmOQCUYzvnrft/()111{{{111)(|/tjnuzYJQOmwpbkho**#MWW&%%%%[email protected]@@@$$$$$$$$           //
//    [email protected]%%%%%88&&WWM#*ooabdpqqqwmO0LCJUYXzcvuunnnnuvvczXUJCQ0Zmqdbkao**#MMW&&8%%%[email protected]$$$$$$$$$           //
//    @@@@BBBBB%%%%%%88&&&&W&#*ohbddppqqdpqwmmZZOO00QQQ0000OZmmwqpdbkhaoo*#MMMMW&&88%%%[email protected]@@$$$$$$$           //
//    @@@@@@@BBBBBB%%%%8888&&WM*oahbbbobdddddbbdbdddddddddbbkkhaaoo**###MMWWW88&&8%%BBB%[email protected]@@@@@@@$$$$           //
//    @@[email protected]@@@[email protected]%B%BB%%88&WW#*ooMohhhkhhahhk##aaaaaaaaaooo*#*##MMWWWW&88888%%%%[email protected]@[email protected]@@@@@@@@@@@@@           //
//    @@@@@@@[email protected]@B%%BBBB%BB%%%88&WM&WM###***ooo#&W*oo**#*###***M##8W&&&88%%%%%8%[email protected]%@@@@@@@@@@@@@@@$$           //
//    @@@@@@@@@[email protected]%%%88%88&&&&WWMMMWW*8#&WMMMMMMWWMWWWW&W&%88%%%%%[email protected]@@@@@@@@@@@@@@@@@@@$$           //
//    @@@@@@@@@@@@@[email protected]%%%%%8888&W8WMM%8&WW88&W&&&&88888888%%BBB%%%%[email protected]@@@@@@@@@@@@@@@@@@@@$$$           //
//    [email protected]@@@@@@@@@@@@BBB%[email protected]@BBBBBBBB%%%8%8&&&&%888888%%8%8%%%%%%%%%[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@BB%[email protected]@@@BBBBBBBB%%%%%%%%%%%%%%%%%BB%%[email protected]@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$           //
//    [email protected]@[email protected]@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Elnz is ERC721Creator {
    constructor() ERC721Creator("Life in Death", "Elnz") {}
}