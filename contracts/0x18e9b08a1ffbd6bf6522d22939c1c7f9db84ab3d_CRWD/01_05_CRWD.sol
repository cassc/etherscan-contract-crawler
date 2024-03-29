// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CROWD
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ½w╝▄▄▄▄╬╠┘Å▓╬          `╙╣R║╬▌▓Ñ▐#╬╣Æ▒r.   ,  . -     '_   __⌐╚²╔▓▒║▒╠▄▄▓╢▓╣╬╠╩Φ    //
//    ▓▄▄▄▄▄,,,[╠╙]^   `        ╙╣╣Ñ▒▒╣╫▓▓▓╓^`   ╒``      '     `  r  ╠'J▀╣^ ╣▓▓▌φ╣Γ╙▓    //
//    ▓▓▓▓╝┘_,╦╣▀╝≈ⁿ-    -        ╙▌╝Ñ▀▓▓╣▓▒'    `'`░²_ ⁿ `          _∩  _'╫x╖╙▓▓▒φ╢▀╙    //
//    ╙ªª%%▀▀╙`_R`  _             ║▌╫╬╬▓▓▓╣╬|     `²╓ -              ` _ `²A²~▄╙╫╫╫φµ▄    //
//    `````         '          _▄▓╬▒▒╣▓╣╣▓╬Öφ      "-▐▄__,.,         _,=Ñû╚ `'_ `┌  `     //
//                         _╓▓▓╬╬Ñ╣Ñ▓╩╬╬╩` '^`    _.⌐'╚`I║R▄H] _     φ=ª╟▓ÖH_       _     //
//                   _,,,_" ╫▌▓╣╣▓╢╬▄φ▓,-ⁿ^▄▓▒╠▄½▒▓╣╣Ñ^ª║K╩⌐..` _    ╣Ü⌐║▓╬▒ΩP▒{≈_____    //
//          ╦╬╗▒A▌▓╣▓▓▓▌╣  _▓▓▌├▒ÜÑ╩HÖ┘╙_  `   .╣╬ '_.÷╦▓D▒w_      _ ▒,½╣╬Ü÷`!╔`    -     //
//       _ⁿ^^╙_  `")3╠T▒║▓▀^∞█░ ^²╙[         j╨Ö▄,ⁿ▄  ╣▓▓▓▄▓ Åª▀≡ -  ╢_ ╟ --'____  _,,    //
//       `_, -_-QÅ╟▌▄▓▀Ö╓─-'╙╣╓¼@«      __.[Z╫w`, _╚╢▀%╝╣╬@^`       -'_ ' -¬  _▄▓▓██▀▀    //
//    _ _ '_,▄@╫^_▀▓▓▀_.< =▓▓▓╬╣K╠¼-._^ '_,╣▒╟▓▓▓▓▓╣╫4╝ΓRD>              ` _╓R╓▄╣▀_       //
//                   _ ≈` `^_▓▓╣φ'->    -._ ▀j▓`=░¼^]╔╜^                   "╒▀╙   __,.    //
//    ___               ~∞ⁿ- ╫▓╝Ç⌐╚,ⁿ.'     ¬╬╫╬Æ╩^^                   _,≤"`     __╗╓▄    //
//    U.__   .. -╒⌐∩X      ╓▓▓╣░H≈^-_        _"▓,^                    ▀` _   _«^ ▄▀▄≡▄    //
//    ²D▒1φ▓▓φ▓▓@▄▄╣╓╓▄▄@▓▓▓▌▓╬R,`_/^+_     '`.─¥ÑQ_-                     ,A╙ __⌐`╙▄╣╬    //
//    _,▓▀▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓╟╬╝╩j- ∩:╚^   ._'-,_ .   'Φ⌂-               _   + ╬JY╗▄▄▄╠▄    //
//    ▓╫▓▓▓╬▓▓██████▓█▀▓▓█╬╬▀╬RÜ{∞     _.j▒WD²╠φ<|--^╔Å▒          ╒φ▓▓╝¬ -╬N∩ -     ``    //
//    =╝╬╣╬▓▓Ñ▓▓▓█▓▓▓▓▓▓▓╬▓▓▓╠∩£  =RRÜ^^'╚╩╬R╩╚▄▄▓▓▓▄ - .        ,▀╨. ` ╒▓▒▓╠_ ⌐_         //
//    ^"╙%Ü╟▌▓▓▓▓╬╫▓▓▓╫▓╬╬╣▓Ö jHP,φ▓▓▓▓▓▓C,╙ÑD▓▓▓▓▓╣½=▓▓╬φ╖      _▄{._┌.▓▓╬▓╣▒=_          //
//    ,     ▓"▀╝╟▓╣▌╣▓▓▒╨╫╟^   ª` Ö╘`Ü╙╝╚ 'Ü╗C█╙1╙▒²^╙╙╬ÖQ▒U_   ,"7^╙▓⌐/╣█╬█▀Ñjy          //
//    `' ___   `▌╚╚╫Å╠^D²/.` _=-            `_╘_▒╣@@╣╣Æ╛═.╠╩/.  ╫╬▄▄╠`  '▓▓█▓,#`          //
//    j ▓█▓▀^  '╙H%╝╬∩`_| _ .╧`        `    .⌐^ ╙ÜÅª╓ⁿVM╧`≈╛Hr_ └╬▓▓Ω⌐   ▓███▓▌φ ⌐        //
//    %û⌐' =         `- ⌐-   `  _  -   ___  _,__╓A"∩ ╚"*,'.(/^_- ▓█▓▓▒║Ü-█▓▌█▓▌▓@▌ `┌     //
//     __-_,___        Ü_- _╘_     _«"T[L╙'''| ┌|╒╔Ñφ╥ΦφÇ╙φ -^_-_┘▓▓▓▓╚¼▓▀╣██▓█╣█▓║=      //
//    _╓╗▓▀╙╙""╙^w_   `-r ¬| _ - ┌Ö\`,φU▒▄▓▒nW▌╫Ü╠▄_╩Ñ╬▀Ñ)=`.|= ,⌐╙▀▌╩▌▓▓╬╩╣▓▓▓█▓█▓▓_Γ    //
//    Ö. __,,▄▄__  "v  _`_ Ü - ,▀_Ä▓KÖÖ╣╣▓▌▄▄▌╫▓▓████▓╬ª╚▒^_ . √Xr_ ▓▓▓▓▓╟╬╬╣╣▀█▓█▓▓▓▒    //
//    ▌╟^"╙ `   └▀╗' '╦..-.   ╣Ñ╫║½▄▄▓█▓██████████▓▓▓▀╟Ω∞ⁿ'A,_Hi∩Ü╓v ╙▓▓╝▀▌▓ÆW~╫▓╝╜▓▄Σ    //
//    _,▄φ▓▓▓▓▓▓▓▓▓▓N *▓-_|___ R1Æ╬╬╝▓██▀▀▓▀▀▀╙╙╩ '_▄▀╓[░_^,_[,=╩'^÷^.▐▓▄_-╠▓▀▀▓▓▓▓▓▄▌    //
//    ███▓█▓█▓▓▓▓▓▓▓▓▒  ▌..``   w╙_/_^--╠╢╬╠▄ÖH#ΦÆ▀╙{╙⌂`╠jR▌Φ╗▄▄▄▄▄▓▓▄██╣▓╗,_   "╙╙▀▀▀    //
//    ███▓▓▓▓▓▓▓╫▓▓╬▓▓▄ █ . --  ?2^≥Ω╓^.  .░>╙╘ _╩" `,«R╔Ö╬╠ ╬╬╬DΦ▐▓▓▓▓▓╬╝╬═Ω½w____       //
//    ██████▓▓▓▓▓▓▓▓▓▌. ▌'¬  ÷^   `∩^╚▀╫▀Ñ╗▄,`_,▄╗@▓╬▄╫╠Ä╠[-∩╚Γ½! ¬▓▓▌#╣▓╣▄#¥ⁿ^ⁿ╗▄_ _     //
//    ▓▓█▓█▓▓▀╠▓▀╙[▓Ö `▐     `_-   ,..-∞ΩÄ╚0▒@╬╬╬║╙▒▀╬╬╠╚H╙`-░▄▓▓▄▄▄▄,   _ ,T^«,   `"º    //
//    ╟╙▌╙^```_.÷Γ╠▄⌐    -    ╗▒-_.⌐       ` ' ^` \¼\¼H╠  ,▄▓▓▀▀▀╬▄╦▓▓▓▓▓▓╫▄▄▄Q╔▓φ+=╗_    //
//    "ⁿ%≈≡═▀""    _-       ' ▓▌^         _       _  P ¼#▀▀╠▄▓▓╬╩▀▀▓▌╣▓▓▓▓▓▓▓▀╙╬>▄╣▓▓▓    //
//       "⌐.   __▄▌ _      _┌▐▄▄_             ` `` ≈ⁿ╣╣╣▌╬▓▀╙╬▄╣Ü╠▓_╖"ª%▀╝*%ª"▐  ▄Ñ^      //
//    ."ⁿ«≈≡⌐@▀▀╙`    ▄Φ▓▓▓╫▄▄▌▄║╬▀▓ _ '¬.__ ,___,╓╓╔φΦ▌╠╬▀▀▀╫╬K╗╠▒     ` '^',▄K╬² ./«    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract CRWD is ERC721Creator {
    constructor() ERC721Creator("CROWD", "CRWD") {}
}