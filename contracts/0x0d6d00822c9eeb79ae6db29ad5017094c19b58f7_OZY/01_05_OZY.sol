// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OZY WORLDY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    SSSSSSSSSSSSS%%SSS#####SSS%?*++*+++++++++++++*++++++****?%SSS######SSSSSSSSSSSSSSSS******+    //
//    SSSSSSSSSSSS%??SS###########SSS%%?????*******????%SSS#SS############SSSSSSSSSSSSSSS%???*??    //
//    SSSSSSSSSSSSSS%%SSSSSSSS####S###############################S##SS%S####SSSSSSSSSSSSSSSS*%S    //
//    SSSSSSSSSSS%%?***+*??%SSSSSSSSSSS######SS####SS#S#SSSSSSSSSSSSSSSSSSS%%?**?%SSSSSSSSSSS?%S    //
//    SSSSSSSSS%?*****++**++**?%%SSSSSS%?%%SSSS%%%%%SS%SSSSSSSSSS%%%??***+++++++++**?SSSSSSSS?%S    //
//    SSSSS%%?*********?*****++*****???****??*******?**?*?*****+*++*++++**+++++++++++*?%%SSSS?%S    //
//    SS%?************?**************+++++**+**?**********************++***++++++++***+++*%S%?%S    //
//    %?******?******?****?********************?****?*****?****++++++*++++++++++++++*++++**%%%%S    //
//    %***++**+++********???***?****?**********?******+*+**++++*++++++*++++++++++++++++++*?%%%%S    //
//    %%%%???*+++++**++**?****???????*********+**+++*++**+*++++**+++******++++++++++++++*?SS%S%S    //
//    %%%SSSSS%%???*+++++++++*******?***++**++********+*++**+++****+*****++++++++++++*?%SSSS%S%S    //
//    S%%SSSSS%S%%SSS%%%%?*%??%%%%%??**********?******++***?*+++***?*+******++*?%%%SSSSSSSSS%S%S    //
//    %S%SS?%%?%?%%%SSSSSS#############S###S####SSSSSS%%%%%%S%%SSS##SSS#S#S#SSSSSSSSSSSSSSSS%S%S    //
//    %S%S%?%S%%%%%%SSSSS%S#######################################@#########SSSSSSSSSSSSSSSS%S%S    //
//    SSSSS%SS%%%?S%SSSSS%?###################################################SSSSSSSSSSSSSS%S%S    //
//    SS%SS%SS%%S%S%SSSSSS%S####################################################SSSSSSSSSSS%%S%%    //
//    %SSSSSSSSSSSS%SSSSSS%%############################SSSSSS#SSS###S##########SSSSSSS%%SS%%S%?    //
//    SSSSSSSS%%SSSSSSSSSSS%#####S####SSSSSSSS##########SSSS#SS##############@@SSSSSSSSSSSS%%S%?    //
//    %%SSSSSS%%%%%%SSSSSS%S####SSSSSSSS################SSSSS##SSS##S########@#SSSSSSSS%SSS%%S%*    //
//    %*?%%*+*?%%%%?%%*?####@############################SSSSSSSSSSSSSS######@SSSSSSSSS%SSS%SS%?    //
//    SS%%%?%%SSSSSSS%*%#@#SS##########@#########SSS########SS##############@#SSSSSSS%%%%SSS%%%*    //
//    %SSSSSSSSSSSSSS%?%S###?%##########SS#####%?**+%#################S##S##SS%SSSSS%%?**??*****    //
//    S%%%SSS%SSSSSSS%??S###SSSSS%?*+*%?;;*%S%S*+**+*S#SSS?**+*%%%%S####S%SS%%SSSSSSSS%%?***????    //
//    S%%%S%SSSSSSSSS%%?%S#SSS####SSS%%%%?%%%S%+++??+?##%%S%???%%??%S###SSSSSSSSSSSSSSSS%?????**    //
//    S%%%S%SSSSSSSSSS%%SSSS%S###SSS##SSSSSSSS?+++*?+*##SSS%S######SS###S%SSSSSSSSSSSSS%%SSS%S?*    //
//    S%%%%%SSSSSSSSSS%%SSSS%?S#########SS#SSS*+**+**+?*?SS%SSSSSS#####S%SSSSSSSSSSSSSSSSSSSSS**    //
//    S%%S%%SSSSSSSSS%%%SS%SS??##########S?*SS*+***?*+***?#SSS%%%SS####SSSSSSSSSSSSSSSSSSSSSSS?*    //
//    %%%SSSS%SSSSSSSS%%S%%SS%?S#########%**%S?***???%SS######S%S%S###%*??%%%%%%%%%%%%%%%SSSSSS%    //
//    %%SSSSS%SSS%SSSS%%%%SSS%%%S######SSS%S##S#SSSSSSSS%%%%S####S###S?****?*????**???????*%SSSS    //
//    S%%SSS%SSSSSSSSSS%%%SSS%S%?#########S%%???**++***++++++*?%#####S??%SSSSSSSSSSSSSSS%%+%SSSS    //
//    S%%%SS%SS%SSSSSSS%%SSSS%%%*?#####%????*;;*???*;;+*????*??+?####%*%SS%SSSSSSSSSSSSS%%*?SSSS    //
//    S%SSSSSSSSSSSSSSS%%SSSS%%%**%####%??%SS+*#@@@%++%##S%*+***?SSSS?*%%SSSSSSSSSSSSSSS%%??SSSS    //
//    %%SSSSSSSSSSSSSSS%SSSSS%%?**?S####S?*+**?%?%%S%%?****?%SS%?***??*%S%SSSSSSSSSSSSSSS%**SSSS    //
//    %%SSSSSSSSSSSSSSS%SSSS%%*++?%%S#####SS?**********?%S######S%?+;:;*?%S%SSSSSSSSSSSS%%??SSSS    //
//    %%SSSSSSSSSSSSS%??%%%?*++*?%%SS%#########SS###S###########SS%%?*;::+%%%SSSSSSSSSSSSS?*SSSS    //
//    %%S%SSSSSSSSSS%?*****+;*%%%%%%S%%######################SSS%%%SS%?*;*%?%%%%SSSSSSSSSS?*SSSS    //
//    ?%%%%%%S%%S%?***+++++;+?%%??%%%SSSSS###############SSS%SSSSSSSS%%?****???%%%SSSSSSSS?*%SSS    //
//    ???*********+*+++++++;?%%%?*???%SSS%%%S#S####SSSSSSSSSSSSSSSSSS%%*+*+++***+**??%%%%S%*%SSS    //
//    ???%%??%?*+++*+++++++;?%%%???%%%SSSSSSSSSSS%%SSSSSSSSSSSSSSSSS%?%*+++++++++++*++++*****??%    //
//    %%%SSSS%*++++*+*+++++;*%%%?%%%??%SSS%%%SSS%SSSS%%SSSSSSSSSSSSSSSS*+++++++++++%**++++++*+++    //
//    %%SSSSS?*++++**+++**++*%%%%%%???%%%%%%%SSSS%S%SSSSSSSSSSS%%%SSSS??+*+++++++++%%%%%%???????    //
//    %SSSSSS***+++*******++?S%SSSSSS%%SS%%%%SSSS%SSSSSSSSSSSS%%%%%%%%??+++++*+++++%%%%%%%*+%???    //
//    SSSSSS?++**+**********?%%%SSSSSS%%%%%%%SSSS#SSSSSSSSSSSSS%%%%%%%%++++++*+++++?*%%%%?*;*+++    //
//    SSSSSS**++*+*********+?S%%SSSSSSS%%%%%%SS####%%SSSSSSSSSSS%%%S%%%++*+++**++++?+S%%%%?+????    //
//    SSSSSS+*;+*+*+*******+*?%%SSSSSSSS%%%%%%%[email protected]##%%SSSSSSSSSSSSSSS%%?*+++++*+++++*?SS%%?%*????    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract OZY is ERC721Creator {
    constructor() ERC721Creator("OZY WORLDY", "OZY") {}
}