// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tyler Durden
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%?%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%??????***********?%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%***++*************+++++*%SSSSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*++*****+********+++++;;;;+%SSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%%%%?**+++++++++*******+++;;;:::;%SSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSS%%??******+++++++********+++;;;;++;;%SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSS%%?*+++++++++++*%%%%%SSSSS%%?+::;+++**%%SSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSS%%??*+++++++;;;?????SSSS%%SSSS%+;:;???%%%SSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS%%???*+++;+;;;;;*??%%%%%???%SSSS%;++++????%SSS%SSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS%%?***++;::;*%%;+?%%SS%SSSSSSS%**+?**+%?+;:+SSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS%%?*+++;;;*%%??%%%SSSSSSSSSS#*,,,+****+:,,..?SSS%SSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSS%??**++++?SS%?%%???%S%%S%%%SSS%::+*+++*+:,,..+SSS?SSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%???****?%S%?*++;;;++*?%SSSSS%????*++*??+::,,,;%S%%SSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%??????%%***+;;;;;;;;;++*???%%%%%*++%S%?;+*:;;?%%SSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%?****+;;****+;;;;;;;+++********?*?????*+*+:,,*#SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS?%%+*;+;;;+***+;;;;;;++++++++*****??%%?***+++,+#SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS?S+;+?*;;;+***+;;;:;;++++++++++*????***++*+;;+;SSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%%++??:;;;++++;;;;;:;;+++++;;;+*?????%?*+?#S+;+SSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSS?*+?+:;;+?+*+++;;;::;;;;;;:;;++**?%%%%??*??*;;%SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS%*+;;;+?S?**+++;;;:;;;;;;:;;+********??*+;;:,*#SSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSS%??%%%?*+***++;;;;;++;;;;;+********++**+:,,;SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*+;;;++****++++++++++++++*******++;::,,,;SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*+;;+++*?***********+++++***???%?*;:::,:*SSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?++++++**???????????*****???%%S%%?+;;;;+SSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*++++++++*?%%SSS%%%%%%%%%%%%SSS%?****+?SSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS*+++++++++*?%%SSSSSSSSSSSSS%%%SS%%%?%SSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?+++++++++**????%%%%%%SSS%%????*%SSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%+;;++++******?*?*******+++;::,,*#SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS*++++++*************++;::,,,,,,;SSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS*++++++****************;:,,,,,,:%SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*+++++++***************+:,,,,,,,*SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS?**+++++++*************+;:,,,,,,,;SSSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSSSSS?*++*+++++++************+;::,,,,,,,:%SSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSSS%?*+++++++++++++****++****+;:,,,,,,,,,,?SSSSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSSSS%?++++++++++++++*****++++**+;::,,,,,,,,,;?%SSSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSS%*?%%%?*+++++++++++*******++++++;::,,,,,,,,,:+*?SSSSSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSS%???%%%%%*+;;;;;+++++*******+;;:;::,,,,,,,,,,,:;;*%%SSSSSSSSSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSS%%++*+?%?%?*;;;;;;;;+++******+;:,::::::,,,,,,,:;++?%?%%SSSSSSSSSSSSSSS    //
//    SSSSS%%%%%%%%SSSSSSS%%??%SS%???%?*;;;;;+++********;:,,::;;::,,,,:;+***+*%??SSSSSSSSSSSSSSS    //
//    SSS%%%%%%%SS%SSSSSSS%?%%%SSSS%???%?*+++++++++++++++:,,:;+;:::::;;;;;;;;;+?????%SSSSSSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSS%%%%?%SS%**????*++++++++++;::;;:,:;+;:;+;:::::::::::??*?**?%SSSSSSSSS    //
//    SSSSSSSSSSSS%SSSSSSS%?%?%**SS%%+*????*+++++++++;::;;;::;+;:;+++;;;:::::::+%*????**%SSSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSS%%?%%%SS%%?++?????*****+++;;:;;+;;;;;;++*++;;;::::::;%*?*++*+*%SSSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSSS%?%SSSSS%*++??????******++;;;;;;;;+++++++;;;::::::+%*??***++*%SSSSS    //
//    SSSSSSSSSSSSSSSSSSSSSS%%???SSSSS%*+?S%????****+++++;;;::;++++++;;;;::::::+%????%%????%SSSS    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract TD is ERC1155Creator {
    constructor() ERC1155Creator("Tyler Durden", "TD") {}
}