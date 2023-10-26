// SPDX-License-Identifier: MIT

/// @title MLow Editions
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                      ◹◺
◹◺    MLOW                              ◹◺
◹◺    ¯\_(ツ)_/¯                         ◹◺
◹◺    ¯\(ツ)/¯                           ◹◺
◹◺    ʅ(ツ)ʃ                             ◹◺
◹◺    乁(ツ)ㄏ                             ◹◺
◹◺    乁(ツ)∫                             ◹◺
◹◺    ƪ(ツ)∫                             ◹◺
◹◺    ¯\_₍ッ₎_/¯                         ◹◺
◹◺    乁₍ッ₎ㄏ                             ◹◺
◹◺    0≤N<2|S| di>0                     ◹◺
◹◺    ¯\_(ツ)_/¯                         ◹◺
◹◺     ¯\(ツ)/¯                          ◹◺
◹◺     ʅ(ツ)ʃ                            ◹◺
◹◺     乁(ツ)ㄏ                            ◹◺
◹◺     乁(ツ)∫                            ◹◺
◹◺     ƪ(ツ)∫                            ◹◺
◹◺     ¯\_₍ッ₎_/¯                        ◹◺
◹◺     乁₍ッ₎ㄏ                            ◹◺
◹◺     ʅ₍ッ₎ʃ                            ◹◺
◹◺     ¯\_(シ)_/¯                        ◹◺
◹◺     ¯\_(ツ゚)_/¯                       ◹◺
◹◺     乁(ツ゚)ㄏ                           ◹◺
◹◺     ¯\_㋡_/¯                          ◹◺
◹◺     ┐_㋡_┌                            ◹◺
◹◺     ┐_(ツ)_┌━☆ﾟ.*･｡ﾟ                  ◹◺
◹◺    ¯\_(⌣̯̀ ⌣́)_/¯                    ◹◺
◹◺     ¯\_(ಠ_ಠ)_/¯                      ◹◺
◹◺     ¯\_(ತ_ʖತ)_/¯                     ◹◺
◹◺     ¯\_(ಸ ‿ ಸ)_/¯                    ◹◺
◹◺     ¯\_(ಸ◞౪◟ಸ)_/¯                    ◹◺
◹◺     ¯\_(　´∀｀)_/¯                     ◹◺
◹◺     ¯\_(Φ ᆺ Φ)_/¯                    ◹◺
◹◺     ¯\_(´◉◞౪◟◉)_/¯                   ◹◺
◹◺     ¯\_(´・ω・｀)_/¯                    ◹◺
◹◺     ¯\_(˶′◡‵˶)_/¯                    ◹◺
◹◺     ¯\_(ಥ‿ಥ)_/¯                      ◹◺
◹◺     ¯\_(；へ：)_/¯                      ◹◺
◹◺     ¯\_(ᗒᗩᗕ)_/¯                      ◹◺
◹◺     ¯\_( ´･ω･)_/¯                    ◹◺
◹◺     ¯\_(๑❛ᴗ❛๑)_/¯                    ◹◺
◹◺     ¯\_(´°̥̥̥̥̥̥̥̥ω°̥̥̥̥̥̥̥̥｀)_/¯    ◹◺
◹◺     ʅ（´◔౪◔）ʃ                         ◹◺
◹◺     ┐(￣ー￣)┌                          ◹◺
◹◺     ★｡･:*¯\_(ツ)_/¯*:･ﾟ★              ◹◺
◹◺                                      ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract MlowEditions is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "MLow Editions",
        "MLOWE",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}