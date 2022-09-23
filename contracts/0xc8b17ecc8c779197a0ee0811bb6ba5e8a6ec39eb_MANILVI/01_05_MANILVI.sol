// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manilvi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    //
//    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*****    //
//    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*??%%%%    //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++?SSSSSSS    //
//    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%SSSSSSS    //
//    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++++++++++++++++++++++++++**??%%%%??????***++++++++++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++*???*++++++++++++++++*?%%SSSSSSSSSSSSSSS%%?**++++++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++?SSS%++++++++++++++*?%SSSSSSSSSSSSSSSSSSSSS%%?+++++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++?SSS%+++++++++++++*%SSSSSSSSSSSSSSSSSSSSSSSSS%?*+++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++?SSS%++++++++++++*%SSSSSSSSSSSSSSSSSSSSSSSSSSS%%*++++++++++++++++++++++++++*SSSSSSSS    //
//    ++++++?SSS%+++++++++++*%SSSS%%%SSSSSS?*%SSSSSSSSSSSSS%?++++++++++++++++++++++++++*%SSSSSSS    //
//    ++++++?SSS%+++++++++++%SSSS%%%SSSSSS%++?SSSS%%S%SSSSS%%*+++++++++++++++++++++++++*SSSSSSSS    //
//    ++++++?SSS%++++++++++*%SSSS%%%SSSSS%?+++%SSSS%%%%%SSSS%*+++++++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%++++++++++?SSSS%%%%SSSSS%*+++?SSSSS%%%%SSSS%?++++***********++++++++++?SSSSSSSS    //
//    ++++++?SSS%++++++++++?SSSS%%%%SSS%%%*+++*%SSSS%%%%SS%%%?++*?%%SSSS%%%%%%??*++++++?SSSSSSSS    //
//    ++++++?SSS%++++++++++*%SS%%%%SSSSSS%?+++*%SSSS%%SSSSSS%*+?SSSSSSSSSSSSSSS%%?+++++?%SSSSSSS    //
//    ++++++?SSS%++++++++++*%%S%%%%SSSSSS%%*++?SSSSS%%SSSSSS?++%SSSSSSSSSSSSSSSS%*+++++?%SSSSSSS    //
//    ++++++?SSS%+++++++++++?%SS%%%SSSSSSS%?+*%SSSS%%%SSSSS%*++?%%%SS%%%%SSSSS%%*++++++?SSSSSSSS    //
//    ++++++?SSS%+++++++**???%SSSSSSSSSSSS%%%%SSSSS%%SSSSS%?++++*???????%%%%??**+++++++?SSSSSSSS    //
//    ++++++?SSS%+++++?%%%%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%*+++++++++++++****+++++++++++?SSSSSSSS    //
//    ++++++?SSS%++++?SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*+++++++++++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++*%SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS%?*+++++++++++++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++*%SSSSSSSSSSSSSSS%%%%%%%%SSS%%??**+++++++++++++++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++?SSSSSSSSSSSSSS%%%?+*********+++*???*++++++++++++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++?SSSSSSSSSSSSSS%%%*+++++++++++++%SSS%+++******+++++++++++++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++%SSSSSSSSSSSSSS%S%?+++++++++++++%SSS%%%%%SSSSS%%%%%%???**++++++++++?SSSSSSSS    //
//    ++++++?SSS%+++%SSSSSSSSSSSSSSSS%?++++++++++++*SSSSSSSSSSSSSSSSSSSSSSSS%%?++++++++?SSSSSSSS    //
//    ++++++?SSS%++*%SS%SSSSSSSSSSSSS%%++++++++++++?SSSSSSSSSSSSSSSSSSSSSSSSSS%*+++++++?SSSSSSSS    //
//    ++++++?SSS%++*%SS%SSSSSSSSSSSSS%%*++++++++++*%SSSSSSSSSSSSSSSSSSSSSSSSSS?*+++++++%SSSSSSSS    //
//    ++++++?SSS%++*%SS%SSSSSSSSSSSSSS%*+++++++++++?SSSSSSSSSSSSSSSSSSSSSSS%%?*+++++++?%SSSSSSSS    //
//    ++++++?SSS%++*%SS%SSSSSSSSSSSSSS%*+++++++++++*SSSSSSSSSSSSSSSSSSS%%%?**++++++++*%SSSSSSSSS    //
//    ++++++?SSS%++?%SSSSSSSSSSSSSSSSSS%?%???*+++++*SSSSS?**??????????***++++++++++++%SSSSSSSSSS    //
//    ++++++?SSS%++?%SS%SSSSSSSSSSSSSSSSSSSSS?+++++*SSSSS?++++++++++++++++++++++++++*%SSSSSSSSSS    //
//    ++++++?SSS%++?SSSSSSSSSSSSSSSSSSSSSSSSS%+++++*SSSSS?++++++++++++++++++++++++++*SSSSSSSSSSS    //
//    ++++++?SSS%++?%SSSSSSSSSSSSSSSSSSSSSSSS?+++++*SSSSS?++++++++++++++++++++++++++?%SSSSSSSSSS    //
//    ++++++?SSS%++?SSS%SSSSSSSSSSSSSSSSSSSSS?+++++?SSSSS?++++++++++++++++++++++++++?SSSSSSSSSSS    //
//    ++++++?SSS%++?SSS%%SSSSSSSSSSSSSSSSSSSS?+++++?SSSSS?++++++++++++++++++********%SSSSSSSSSSS    //
//    ++++++?SSS%++?SS%%%%SSSSSSSSSSSSSSSSSSS?+++++?SSSSS?+++++++++++++**??%%%SSSSSSSSSSSSSSSSSS    //
//    ++++++?SSS%++?SS%%%SSSSSSSSSSSSSSSSSSSS?+++++?SSSSS?+++++++++++*?%SSSSSSSSSSSSSSSSSSSSSSSS    //
//    ++++++?SSS%++%SSS%%SSSSSSSSSSSSSSSSSSSS?+++++?SSSSS?++++++++*?%SSSSSSSSSSSSSSSSSSSSSSSSSSS    //
//    ++++++?SSS%++%SSS%%SSSSSSSSSSSSSSSSSSSS?+++++?%SSSS?+++++++?%SSSSS%%%SSSSSS%%SSSSSSSSSSSSS    //
//    ++++++?SSS%++%SSSSSSSSSSSSSSSSSSSSSSSSS%+++++?SSSSS?+++++*?SSSSS%%%%SSSS%?*++?SSSSSSSSSSSS    //
//    ++++++?SSS%++%SSSSSSSSSSSSSSSSSSSSSSSSS%+++++?SSSSS?++++*%SSSSS%%%SSSS%?*++++?SSSSSSSSSSSS    //
//    ++++++?SSS%++%SS%SSSSSSSSSSSSSSSSSSSSSS%+++++?SSSSS?+++*%SSSSS%%SSSS%%?++++++?SSSSSSSSSSSS    //
//    ++++++?SSS%++?%SS%%SSSSSSSSSSSSSSSSSSSS?+++++?%SSSS?+++%SSSSS%%SSSS%%?+++++++?SSSSSSSSSSSS    //
//    ++++++?SSS%++%SSS%%SSSSSSSSSSSSSSSSSSSS?+++++?%SSSS?++?SSSS%%%%SSS%%?++++++++?%S%SSSSSSSSS    //
//    ++++++?SSS%++%SS%%%SSSSSSSSSSSSSSSSSSSS?+++++?%SSSS?+*%SSS%%%%%SSS%%*++++++++?%S%SSSSSSSSS    //
//    ++++++?SSS%++?%S%%%%SSSSSSSSSSSSSSSSSSS?+++++?%SSSS?+?%S%%%?%%%S%%%?+++++++++?%%%SSSSSSSSS    //
//    ++++++?SSS%++%%%%%%%SSSSSSSSSSSSSSSSSSS?+++++?SSSSS?*%SS%%%%%SSSS%%*+++++++++?%%%SSSSSSSSS    //
//    ++++++?SSS%++%%%%%%%SSSSSSSSSSSSSSSSSSS?+++++?%SSSS??%SS%%%%%SSS%S%++++++++++?%%%SSSSSSSSS    //
//    ++++++?S%S%++?%S%%%SSSSSSSSSSSSSSSSSSSS?+++++?%%S%S??SSSSS%%SSSS%%?++++++++++?%SSSSSSSSSSS    //
//    ++++++?S%S%++?%%S%%SSSSSSSSSSSSSSSSSSSS%+++++?%%S%S??SSSSS%%SSSS%%?++++++++++?%SSSSSSSSSSS    //
//    ++++++?S%S%++?%%%%SSSSSSSSSSSSSSSSSSSSS%+++++?%%S%%??SS%SS%SSSSSS%?++++++++++?SSSSSSSSSSSS    //
//    ++++++?S%S%++?%%%%SSSSSSSSSSSSSSSSSSSSS%+++++?%%S%S??SS%%S%%SSSS%%?++++++++++?SSSSSSSSSSSS    //
//    ++++++?S%S%++?%SS%%SSSSSSSSSSSSSSSSSSSS?+++++?%%S%%??%%SS%%%SSSS%%%*+++++++++?S%SSSSSSSSSS    //
//    ++++++?SSS%++?%SS%%SSSSSSSSSSSSSSSSSSSS?+++++?%SS%S?*%SSSS%%%SSS%%%*+++++++++?S%%SSSSSSSSS    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract MANILVI is ERC721Creator {
    constructor() ERC721Creator("Manilvi", "MANILVI") {}
}